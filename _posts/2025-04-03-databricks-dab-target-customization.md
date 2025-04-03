---
title: "Customizing Target Deployments in Databricks Asset Bundles"
page_title: "Customizing Target Deployments in Databricks Asset Bundles"
excerpt: "Exploring how to structure a DAB project for greater flexibility
  and scalability by leveraging target-specific resource definitions. While
  ensuring each deployment environment receives precisely the resources it
  needs while keeping configurations modular and manageable."
toc: true
toc_label: "Content"
toc_sticky: true
date: April 3, 2025
last_modified_at: April 3, 2025
og_image: /assets/images/posts/databricks-dab-target-customization/header.jpg
---

{% include image.html
    src="/assets/images/posts/databricks-dab-target-customization/header.jpg"
    alt="databricks-dab-target-customization"
    caption="Image Source: <a href='https://www.pexels.com/' target='_blank'>Pexels</a>"
%}

## Introduction

Databricks Asset Bundles (DAB) is a structured way to define, deploy, and
manage Databricks workflows, including jobs, clusters, dashboards, model
serving endpoints and other resources, using declarative YAML configurations.
It allows us to implement software engineering best practices by enabling
version control, CI/CD integration, and automation by treating infrastructure
and data assets as code. DAB simplifies collaboration and deployment across
environments, ensuring easier management and scalability of Databricks
projects.

> If you completely new to DAB, please refer to
> [What are Databricks Asset Bundles?](https://docs.databricks.com/aws/en/dev-tools/bundles){:target="\_blank"}
> before continuing with this blog post.

Using DAB it's possible to describe Databricks resources such as jobs,
pipelines, and notebooks as source files. These files fully describe a project
and code that governs it - providing project structure and
automation for testing and deployment. Additionally, DAB allows us to define
deployment targets which can be fully customized depending on the use case
and project's needs - such as development, staging, and production.

In some cases, specific environments may require additional resources.
For example, staging might include extra testing pipelines that are not needed
in production once validation is complete.

In this blog post we will explore ways of customizing resource deployments
per target.

## Using `include` and `resources`

As we know, Databricks resources are defined by specifying the type of
resource and its configuration under the `resources` in `databricks.yml`.
Resources can include Databricks apps, clusters, dashboards, jobs, pipelines,
model serving endpoints, and more. The following example illustrates how to
define a simple job and a job cluster:

```yaml
resources:
  jobs:
    hello-job:
      name: hello-job
      tasks:
        - task_key: hello-task
          existing_cluster_id: 1234-567890-abcde123
          notebook_task:
            notebook_path: ./hello.py
```

By default, resources can be declared at the top level, making them available
across all deployment targets:

```yaml
# databricks.yml

bundle:
  name: test-bundle

resources:
  ...

targets:
  dev:
    default: true
    ...
  stg:
    ...
  prd:
    ...
```

With this setup, the same resources are deployed to `dev`, `stg`, and `prd`,
ensuring consistency across all environments.

In many cases, different environments require unique configurations. For
example, you might need additional testing pipelines in staging but not in
production. To achieve this, you can define resources specific to each
deployment target:

```yaml
# databricks.yml

bundle:
  name: test-bundle

resources:
  ...

targets:
  dev:
    default: true
    resources:
      ...
    ...
  stg:
    resources:
      ...
    ...
  prd:
    resources:
      ...
    ...
```

By defining resources at the target level, additional resources are deployed
only where needed, while still inheriting the global resources from the top
level. This flexible approach ensures that each environment is optimized for
its purpose without unnecessary configurations.

Be aware that each resource has an identifier. If you use the same identifier
at both the top level and the target level, the target-level definition will
take precedence and override the top-level definition. For more information on
how you can leverage this to fine-tune the configuration for a specific
target, please see
[Override cluster settings in Databricks Asset Bundles](https://docs.databricks.com/aws/en/dev-tools/bundles/cluster-override){:target="\_blank"}.

So far, everything has been defined in a single YAML file, which can make
readability and management challenging as the project grows. Let's explore
some strategies to enhance flexibility, support customizations, and ensure
seamless scalability as the project expands.

The `include` allows us to add a list of path globs that contain configuration
files to include within the bundle. These path globs are relative to the
location of the bundle configuration file in which the path globs are specified.

Therefore, we can structure the project in following form:

```text
project/
├── tests/
│   └── ...
├── resources/
│   ├── pipelines.yml
│   ├── jobs.yml
│   └── dashboards.yml
├── src/
│   ├── notebook_a.ipynb
│   ├── notebook_b.ipynb
│   └── ...
├── databricks.yml
└── ...
```

And instead of using `resources` in a single YAML, we just specify what we
want to include

```yaml
bundle:
  name: test-bundle

include:
  - resources/*.yml

targets:
  dev:
    default: true
    ...
  stg:
    ...
  prd:
    ...
```

Each file in `resources/*.yml` contains its own definition of resources, allowing
for a structured and modular approach to managing YAML files. This separation
keeps resource definitions organized and easy to manage as the project scales.
However, the `include` can only be used at the top level, meaning all
included resources will be deployed to every target.

If we need to add resources for a specific target, we must define resources at
the target level, as shown in the previous example. While this approach works,
it can become cumbersome when managing numerous customizations across multiple
targets. To address this challenge, let's explore a better way of structuring
target-specific YAML files in the next section.

## Separating Target YAMLs

A key advantage of DAB is that the `include` directive isn't limited to
`resources` - it can also be used for other top-level keys like `targets`. 
This allows for a more modular and scalable project structure.

To improve organization and maintainability, we can structure our project as
follows:

```text
project/
├── tests/
│   └── ...
├── resources/
│   ├── pipelines.yml
│   ├── jobs.yml
│   └── dashboards.yml
├── src/
│   ├── notebook_a.ipynb
│   ├── notebook_b.ipynb
│   └── ...
├── targets/
│   ├── dev.yml
│   ├── stg.yml
│   └── prd.yml
├── databricks.yml
└── ...
```

In this setup:
- The `resources/` directory contains shared resources used by all
  environments.
- The `targets/` directory holds YAML files that define the specific resources
  for each deployment target.

Each target file, such as `targets/dev.yml`, includes only the resources
specific to that environment.

```yaml
# targets/dev.yml

targets:
  dev:
    default: true
    resources:
      ...
    ...
```

Similarly, `targets/stg.yml` and `targets/prd.yml` will include the appropriate
resources for their respective environments.


In `databricks.yml`, we can now include the common resources while allowing
each target to bring its own specific configurations.

```yaml
# databricks.yml

bundle:
  name: test-bundle

include:
  - resources/*.yml
  - targets/*.yml

```

This setup provides a structured and scalable way to manage resources, ensuring
that each environment gets precisely the resources it needs without unnecessary
duplication. By splitting resource definitions across separate YAML files for
each target, project teams gain better organization, control, and flexibility.

This modular approach simplifies configuration management, making it easier to
track changes, customize deployments, and avoid bloated YAML files.

## Runtime Editing 

DAB supports
[substitutions and custom variables](https://docs.databricks.com/aws/en/dev-tools/bundles/variables){:target="\_blank"},
enabling modular, reusable, and dynamic configuration files. These features
allow values to be retrieved at runtime, ensuring that resource configurations
can be adjusted dynamically when deploying and running a bundle.

Unfortunately, DAB does not currently support using variables to dynamically set
`include` directives. As a workaround, we can modify the `databricks.yml` file
within a CI/CD pipeline by substituting variables before executing
`databricks bundle deploy`. This approach allows for greater flexibility in
managing environment-specific configurations while maintaining automation in
the deployment process.

We can enhance our project structure by leveraging environment variables to
dynamically set configurations for each target, making deployments even more
flexible.

```text
project/
├── tests/
│   └── ...
├── resources/
|   ├── common/
│   |   ├── pipelines.yml
│   |   ├── jobs.yml
│   |   └── dashboards.yml
|   ├── dev/
│   |   └── ...
|   ├── stg/
│   |   └── ...
|   ├── prd/
│   |   └── ...
├── src/
│   ├── notebook_a.ipynb
│   ├── notebook_b.ipynb
│   └── ...
├── targets/
│   ├── dev.yml
│   ├── stg.yml
│   └── prd.yml
├── databricks.yml
└── ...
```

Where `databricks.yml` looks like

```yaml
# databricks.yml

bundle:
  name: test-bundle

include:
  - resources/common/*.yml
  - resources/${target}/*/yml
  - targets/*.yml

```

In a CI/CD pipeline, we typically pull the DAB code from a Git repository and 
set an environment variable that represents the target deployment environment.
Before running `databricks bundle deploy`, we can dynamically replace
`${target}` with the appropriate environment variable using a simple command
like `sed`:

```bash
sed -i -e 's/${target}/'"$TARGET"'/g' databricks.yml
```

By leveraging this approach, we achieve greater flexibility, allowing each
deployment to dynamically include the correct resources based on the target
environment.

I hope these approaches and examples have provided you with a clearer
understanding of how to structure your Databricks project using DAB. By
implementing these strategies, you can achieve greater target customization
while ensuring your deployment remains scalable, modular, and easy to manage.
