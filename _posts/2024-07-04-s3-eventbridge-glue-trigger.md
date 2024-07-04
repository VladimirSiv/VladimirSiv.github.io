---
title: "Handle Irregular Bursts of files using EventBridge and Glue Workflow"
page_title: "S3 Notification EventBridge Glue Workflow Trigger"
excerpt: "Exploring ways of handling irregular and sudden bursts of
multiple files for data processing using event driven architecture on AWS.
This blog posts showcases how to use S3 notification with EventBridge
to trigger a Glue Workflow that has number of events and batch window
trigger conditions."
toc: true
toc_label: "Content"
toc_sticky: true
date: July 4, 2024
last_modified_at: July 4, 2024
og_image: /assets/images/posts/s3-eventbridge-glue-trigger/header.jpg
---

{% include image.html
    src="/assets/images/posts/s3-eventbridge-glue-trigger/header.jpg"
    alt="s3-eventbridge-glue-trigger"
    caption="Image Source: <a href='https://www.pexels.com/' target='_blank'>Pexels</a>"
%}

## Introduction

In this blog post I'll showcase a Data Solution that handles irregular and
sudden bursts of multiple files for processing purposes. This solution is
event driven and it can buffer multiple files or wait certain amount of
time before processing is actually triggered.

Let's say that you are using Glue job to process data that comes from a
data source. The following is true regarding the data source:
- Data source is pushing files to your landing zone
- Files are pushed irregularly and in bursts
  - **Irregular** - Sometimes you have files coming for a few minutes, but
    then you have gaps of multiple hours where nothing is pushed
  - **Bursts** - When data is pushed, it's usually multiple files in a row. For
    example, 10 files in 2 minutes

You'd like to process these files as soon as possible while keeping costs low
and complexity of data solution and processing pipelines manageable.

Few ideas may pop right away:
- Run a Glue job on a schedule, every X minutes - Obviously, this means that
  a Glue job will be triggered even though files are not present in a landing
  zone, this will lead to high costs and unnecessary Glue job invocations
- Run a Glue job from Lambda that's triggered via S3 notification - When a files
  lands in a bucket, it will create an S3 notification that can be passed to a
  Lambda function that triggers a Glue job. This solution is fine if you are
  receiving one file every X minutes, where X is greater than duration of your
  Glue job. Since we are dealing with bursts of files and want to process
  multiple files at once, this is not viable
- Run a Lambda function that scans a bucket every X minutes, if files are
  present it will trigger a Glue job - In this case, the time window is fixed
  which can lead to undesired behavior. What will happen if Lambda is invoked
  while the burst is in progress? If files are pushed right after Lambda
  invocation, it will have to wait for the next one. Shortening this period
  means increasing frequency of invocations which leads to unnecessary Lambda
  invocations for hours etc

In this post I'll present a better option to handle this case. It relies on
S3 notification being sent to Event Brigde, then using a Rule we match
desired events and set rule target to Glue Workflow, which contains an
event-type trigger.

## How It Works

The following diagram illustrates how different AWS services are connected
in order to create an event-driven data solution

{% include image.html
    src="/assets/images/posts/s3-eventbridge-glue-trigger/overview.jpg"
    alt="s3-eventbridge-glue-trigger-overview"
    caption="Infrastructure Overview"
%}

The process unfolds as follows:
- A file is uploaded to an S3 bucket, triggering an event
- This event is routed to EventBridge
- EventBridge Rule is used to identify and capture specific events
- A rule directs the event to a Glue Workflow
- Within the Glue Workflow, an event Glue Trigger determines the timing for
  initiating a Glue job
- The Glue Trigger starts a Glue job that gathers files from S3 and
  processes them

The most important part of this logic is located in the Glue Trigger. This
trigger is of type `EVENT` and it's using
[EventBatchCondition](https://docs.aws.amazon.com/glue/latest/dg/aws-glue-api-jobs-trigger.html#aws-glue-api-jobs-trigger-EventBatchingCondition){:target="\_blank"}
structure which defines two condition that must be met before the trigger
fires:
- `BatchSize` - Specified number of events received. For example 10 files
- `BatchWindow` - Batch time window after which the trigger fires. For example,
  run a Glue job 15 minutes after the first file is uploaded

The trigger will fire based on whichever of these two conditions is met first
and reset the state.

{% include image.html
    src="/assets/images/posts/s3-eventbridge-glue-trigger/conditions.jpg"
    alt="s3-eventbridge-glue-trigger-conditions"
    caption="Batch Condition Trigger"
%}

Depending on the configuration and the volume from a data source, it can
lead to concurrent Glue workflow runs. Additionally, failure in workflow
execution may occur when the concurrency limit specified for the workflow
does not match that of its individual jobs. Therefore, it's crucial to take
into account the volume i.e. number of events, desired batch configuration,
and design of the workflow for concurrent execution.

> Note: Here we are using S3 option to send events to EventBridge, an
> alternative approach involves setting up a CloudTrail trail for a designated
> bucket and specifying the events to be routed to EventBridge. The outcome
> will be the same, it just depends on your needs and use cases.
> For more information, please see
> [Capture Amazon S3 events through AWS CloudTrail](https://repost.aws/knowledge-center/eventbridge-rule-monitors-s3){:target="\_blank"}

## Infrastructure as Code

This section will explain how we can implement this data solution in
infrastructure as code fashion using AWS CDK. The full code can be found in my
GitHub repository
[aws-examples](https://github.com/VladimirSiv/aws-examples){:target="\_blank"}
under in `s3-eventbridge-glue-workflow` example.

Here, I'll walk you through the implementation, and explain what are we doing
in the code. Please follow the code in `s3_eventbridge_glue_workflow/stack.py`.

First, we start by creating an S3 bucket

```python
bucket = s3.Bucket(
    self,
    id="Bucket",
    access_control=s3.BucketAccessControl.PRIVATE,
    encryption=s3.BucketEncryption.S3_MANAGED,
    versioned=False,
    block_public_access=s3.BlockPublicAccess.BLOCK_ALL,
)

bucket.enable_event_bridge_notification()
```

the `enable_event_bridge_notification()` enables all S3 events to be
routed to EventBridge in `default` event bus. Under the hood, this will
create a Lambda that will push S3 events to event bus, you can see that
by building the CloudFormation stacks.

Next, we are defining a Glue Workflow

```python
glue_workflow = glue.CfnWorkflow(
    self,
    "GlueWorkflow",
    description="Event Driven Glue Workflow",
    name="glue-workflow",
    max_concurrent_runs=1,
)
workflow_arn = f"arn:aws:glue:{region}:{account}:workflow/{glue_workflow.name}"
```

Unfortunately, `CfnWorkflow` doesn't have `arn` attribute, so we have to build
it ourselves using `Stack.of(self).(region|account)`, this ARN will be later
used to reference this workflow.

Next, we define a Glue job

```python
glue_job = glue.CfnJob(
    self,
    "GlueJob",
    description="Glue job",
    name="glue-job",
    role="glue-role",
    command=glue.CfnJob.JobCommandProperty(
        name="glueetl",
    ),
    execution_property=glue.CfnJob.ExecutionPropertyProperty(
        max_concurrent_runs=1,
    )
)
```

Of course, this is just an example job used for illustrating the concept, an
actual job will contain more information and arguments.

Now, we define a Glue Trigger. It will connect to a Glue job and define
event batching conditions

```python
glue_trigger = glue.CfnTrigger(
    self,
    "GlueTrigger",
    description="Event Glue Job Trigger",
    name="glue-event-trigger",
    type="EVENT",
    workflow_name=glue_workflow.name,
    actions=[
        glue.CfnTrigger.ActionProperty(
            job_name=glue_job.name,
        )
    ],
    event_batching_condition=glue.CfnTrigger.EventBatchingConditionProperty(
        batch_size=100,
        batch_window=900,
    )
)
```

`batch_size` has maximum of 100 events, and `batch_window` is defined in
seconds, where 900 seconds i.e. 15 minutes is maximum.

In order for EventBridge Rule to send matched events to a Glue workflow,
we have to define a role with `glue:notifyEvent` permissions

```python
event_target_role = iam.Role(
    self,
    "EventTargetRole",
    description="Role that allows EventBridge to target Glue Workflow",
    assumed_by=iam.ServicePrincipal("events.amazonaws.com"),
)
event_target_role.add_to_policy(
    iam.PolicyStatement(
        effect=iam.Effect.ALLOW,
        resources=[workflow_arn],
        actions=["glue:notifyEvent"],
    )
)
```

Finally, we create EventBridge Rule and connect workflow as event rule
target

```python
event_rule = events.Rule(
    self,
    "EventRule",
    description="Rule to match PutObject event in a bucket",
    event_pattern=events.EventPattern(
        source=["aws.s3"],
        detail_type=["Object Created"],
        detail={"bucket": {"name": bucket.bucket_name}},
    )
)

@jsii.implements(events.IRuleTarget)
class GlueWorkflowEventRuleTarget():
    def bind(self, rule, id=None):
        return events.RuleTargetConfig(
            arn=workflow_arn,
            role=event_target_role,
        )

event_rule.add_target(GlueWorkflowEventRuleTarget())
```

The last part and the use of `jsii.implements(events.IRuleTarget)` requires
some explanation which I provide in the next section.

## Appendix - jsii

While working on this data solution, I've noticed that
[aws_events.CfnRule](https://docs.aws.amazon.com/cdk/api/v2/python/aws_cdk.aws_events/CfnRule.html){:target="\_blank"}
has a bug. It's been already reported [aws-cdk-lib/aws_events: detailType property does not translate to detail-type in rule creation using the CfnRule](https://github.com/aws/aws-cdk/issues/18806){:target="\_blank"}
but no resolution has been implemented yet. The argument `detail_type`
gets mapped to `detailType` when the rule is created in CloudFormation
template. This argument doesn't work, since AWS expects `detail-type`.

Since I don't want to post-process CloudFormation templates or fix AWS' bugs,
I had to use [aws_events.Rule](https://docs.aws.amazon.com/cdk/api/v2/python/aws_cdk.aws_events/Rule.html){:target="\_blank"}.

However, this introduced a different issue. The method
[add_target](https://docs.aws.amazon.com/cdk/api/v2/python/aws_cdk.aws_events/Rule.html#aws_cdk.aws_events.Rule.add_target){:target="\_blank"}
expects parameter `target` of type `Optional[IRuleTarget]`. All the examples
in the documentation are using a special module
[aws_cdk.aws_events_targets](https://docs.aws.amazon.com/cdk/api/v2/python/aws_cdk.aws_events_targets.html){:target="\_blank"}
dedicated for creating classes for different kinds of AWS services that
implement `IRuleTarget`.

For example, adding SQS queue as an EventBridge target, would be easily
done using

```python
rule.add_target(
  target=aws_events_targets.SqsQueue(
    queue=<queue>
  )
)
```

Unfortunately, there is no class for Glue Workflow, and `aws_events_targets`
doesn't have a method for defining custom targets.

This means that we have to define a custom class that implements `IRuleTarget`
and pass information about Glue Workflow target. If you take a closer look at
[IRuleTarget](https://docs.aws.amazon.com/cdk/api/v2/python/aws_cdk.aws_events/IRuleTarget.html){:target="\_blank"}
you'll notice that `bind()` method returns [RuleTargetConfig](https://docs.aws.amazon.com/cdk/api/v2/python/aws_cdk.aws_events/RuleTargetConfig.html#aws_cdk.aws_events.RuleTargetConfig){:target="\_blank"},
which has two parameters:
- `arn` - The Amazon Resource Name (ARN) of the target
- `role` - Role to use to invoke this event target

Meaning, we can specify Glue Workflow ARN as our target and pass the role
which has `glue:notifyEvent` permissions.

In order for this to work with AWS CDK class structure, we have to use
[jsii](https://github.com/aws/jsii) which allows code in any language to
naturally interact with underlying AWS CDK JavaScript classes.

Finally, we arrive at

```python
@jsii.implements(events.IRuleTarget)
class GlueWorkflowEventRuleTarget():
    def bind(self, rule, id=None):
        return events.RuleTargetConfig(
            arn=workflow_arn,
            role=event_target_role,
        )

event_rule.add_target(GlueWorkflowEventRuleTarget())
```

This has been tested and the deployment of CloudFormation stack worked without
any issues.

If you have any questions, please don't hesitate to contact me.
I'm always available to discuss the things I've worked on.

## Resources

- [Build a serverless event-driven workflow with AWS Glue and Amazon EventBridge](https://aws.amazon.com/blogs/big-data/build-a-serverless-event-driven-workflow-with-aws-glue-and-amazon-eventbridge/){:target="\_blank"}
- [Starting an AWS Glue workflow with an Amazon EventBridge event](https://docs.aws.amazon.com/glue/latest/dg/starting-workflow-eventbridge.html){:target="\_blank"}
