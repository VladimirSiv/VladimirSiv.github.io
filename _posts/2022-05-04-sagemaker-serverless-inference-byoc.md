---
title: "SageMaker Serverless Inference using BYOC"
page_title: "SageMaker Serverless Inference using BYOC"
excerpt: "Methods of deploying custom models inside Docker images using the SageMaker and serverless inference"
date: May 4, 2022
toc: true
toc_label: "Content"
toc_sticky: true
last_modified_at: May 4, 2022
og_image: /assets/images/posts/sagemaker-serverless-inference-byoc/header.jpg
---

{% include image.html
    src="/assets/images/posts/sagemaker-serverless-inference-byoc/header.jpg"
    alt="similarity-header"
    caption="Image Source: <a href='https://www.pexels.com/' target='_blank'>Pexels</a>"
%}

## Introduction

As we already know, SageMaker can do basically everything from creating, 
training, deploying, and optimizing ML models. You can use built-in algorithms 
and models, browse AWS Marketplace to find specific model packages, or simply 
create your own - train it using SageMaker and deploy it. Everything is 
streamlined and organized from start to finish.

However, in some circumstances we want a completely custom solution. The idea 
is to bring our own packages and models i.e. BYOC 
(Bring Your Own Container). 
To achieve this we could:
- Extend a prebuilt SageMaker container image - SageMaker provides containers 
for some of the most common machine learning frameworks, such as Apache MXNet, 
Tensorflow, PyTorch etc.
- Adapt an existing container image - Modify existing Docker image to enable 
training and inference using SageMaker

In this article we will focus on deploying our own inference code by adapting 
a Docker image that contains our production-ready model. 
Additionally, we will deploy it as a serverless inference endpoint, which 
means that we don't have to configure or manage the underlying infrastructure 
and we only pay for the compute capacity used to process inference 
requests.[^1]

[^1]: [SageMaker pricing page](https://aws.amazon.com/sagemaker/pricing/?nc=sn&loc=3){:target="_blank"}

To do this we will:
- Create a Docker image and configure it for SageMaker inference
- Push the image to ECR
- Create a SageMaker model based on the Docker image
- Configure a SageMaker endpoint
- Deploy the SageMaker endpoint

There are two ways to do this through code: `boto3` and `CDK` - we will cover 
both.

> Note: We will go through setting up the server and invocation endpoints for 
one model, if you are interested in a premade solution for hosting multi model 
servers please see: [Amazon SageMaker Multi-Model Endpoints using your own algorithm container](https://sagemaker-examples.readthedocs.io/en/latest/advanced_functionality/multi_model_bring_your_own/multi_model_endpoint_bring_your_own.html){:target="_blank"}

## Docker Image

Behind the scenes SageMaker makes extensive use of Docker containers. All the 
built-in algorithms and the supported deep learning frameworks used for 
training and inference are essentially stored in containers. The benefits of 
this approach is that it allows us to scale quickly and reliably. 
Consequently, there are certain rules that we have 
to respect when we implement our own containers:
- For model inference, SageMaker runs the container as:
```
docker run <image> serve
```
This overrides default `CMD` statements in a container.

- Containers need to implement a web server that responds to `/invocations` 
and `/ping` on port 8080
- To get the result from the model, client sends a POST request to the 
SageMaker endpoint, this is forwarded to the container and invoked at 
`/invocations`, then the result is returned to the client
- A customer's model containers must respond to requests within 60 seconds
- SageMaker sends periodic GET requests to the `/ping` endpoint. The response 
can be just HTTP 200 status with an empty body

> See the details at 
[Use Your Own Inference Code with Hosting Services](https://docs.aws.amazon.com/sagemaker/latest/dg/your-algorithms-inference-code.html){:target="_blank"}

To implement our container and satisfy these requirements, we will use 
[Nginx](https://www.nginx.com/){:target="_blank"}
and [gunicorn](https://gunicorn.org/){:target="_blank"}. The idea is to 
create a simple Flask application, set up a WSGI server using gunicorn and 
then use the Nginx as a reverse-proxy.

The structure looks like this:

```
root/
├─ model
│   ├─ nginx.conf       Contains the configuration for reverse-proxy
│   ├─ predictor.py     Contains the Flask application
│   ├─ serve            Starts the Nginx and WSGI
│   └─ wsgi.py          Defines the WSGI application
├─ Dockerfile           Defines the Docker image configuration
```

This can also be found in the [amazon sagemaker examples](https://github.com/aws/amazon-sagemaker-examples/tree/main/advanced_functionality/scikit_bring_your_own/container) 
GitHub repository provided by AWS.

To define a reverse-proxy to gunicorn, use the following configuration in 
[`nginx.conf`](https://github.com/aws/amazon-sagemaker-examples/blob/main/advanced_functionality/scikit_bring_your_own/container/decision_trees/nginx.conf){:target="_blank"}. 
The [`serve`](https://github.com/aws/amazon-sagemaker-examples/blob/main/advanced_functionality/scikit_bring_your_own/container/decision_trees/serve){:target="_blank"} 
will start the gunicorn and a reverse-proxy server.

The [`predictor.py`](https://github.com/aws/amazon-sagemaker-examples/blob/main/advanced_functionality/scikit_bring_your_own/container/decision_trees/predictor.py){:target="_blank"} 
contains the endpoint logic. The GET should check if the 
model is loaded and configured properly:

```python
@app.route('/ping', methods=['GET'])
def ping():
    # Check if the model was loaded correctly
    health = is_model_ready()
    status = 200 if health else 404
    return flask.Response(response= '\n', status=status, mimetype='application/json')
```

Next we define the POST request for `/invocations`, this part of the code 
should implement your custom model predictions:

```python
@app.route('/invocations', methods=['POST'])
def transformation():
    
    # Process input
    input_json = flask.request.get_json()
    data = input_json['input']
    
    # Custom model
    result = custom_model.predict(data)

    # Return value
    resultjson = json.dumps(result)
    return flask.Response(response=resultjson, status=200, mimetype='application/json')
```

In order to build a docker image we define the `Dockerfile`:

```dockerfile
FROM python:3.8

RUN apt-get -y update && apt-get install -y --no-install-recommends \
         wget \
         python3 \
         nginx \
         ca-certificates \
    && rm -rf /var/lib/apt/lists/*

RUN wget https://bootstrap.pypa.io/get-pip.py && python3 get-pip.py && \
    pip install flask gevent gunicorn && \
        rm -rf /root/.cache


# Install all dependencies for your custom model

# Set some environment variables. PYTHONUNBUFFERED keeps Python from buffering our standard
# output stream, which means that logs can be delivered to the user quickly. PYTHONDONTWRITEBYTECODE
# keeps Python from writing the .pyc files which are unnecessary in this case. We also update
# PATH so that the train and serve programs are found when the container is invoked.
ENV PYTHONUNBUFFERED=TRUE
ENV PYTHONDONTWRITEBYTECODE=TRUE
ENV PATH="/opt/program:${PATH}"

COPY model /opt/program
WORKDIR /opt/program
```

Note that the `Dockerfile` should contain the commands that install all the 
dependencies needed for the custom model.

Finally, we have to build and push the image to the ECR. To do this, we can 
use a simple bash script:

```bash
model_name=<model-name>

account=$(aws sts get-caller-identity --query Account --output text)
region=<region>
fullname="${account}.dkr.ecr.${region}.amazonaws.com/${model_name}:latest"
chmod +x model/serve

aws ecr get-login-password --region ${region} | docker login --username AWS --password-stdin ${fullname}

docker build -t ${model_name} .
docker tag ${model_name} ${fullname}
docker push ${fullname}
```

> Note: This script is a simple version of 
[`build_and_push.sh`](https://github.com/aws/amazon-sagemaker-examples/blob/main/advanced_functionality/scikit_bring_your_own/container/build_and_push.sh){:target="_blank"} that is 
provided in the official AWS GitHub repository.

## SageMaker

### Boto3

Once we have the image in the ECR, we can create a SageMaker model. We will do 
this using the
[SageMaker Boto3 Client](https://boto3.amazonaws.com/v1/documentation/api/latest/reference/services/sagemaker.html){:target="_blank"}. 
One of the parameters of `create_model()` method is `ExectionRoleArn`, 
which means that we will have to create an IAM role beforehand or use the 
`get_execution_role()`, please see 
[SageMaker Roles](https://docs.aws.amazon.com/sagemaker/latest/dg/sagemaker-roles.html){:target="_blank"}.

```python
import boto3

sm_client = boto3.client(service_name='sagemaker')

def create_model():
    role_arn = "<role-arn>"
    image = "{}.dkr.ecr.{}.amazon.com/{}:latest".format(
        "<profile>", "<region>", "<image-name>"
    )
    create_model_response = sm_client.create_model(
        ModelName="<model-name>",
        ExecutionRoleArn=role_arn,
        Containers=[{"Image": image}],
    )
    print(create_model_response)
```

If everything went well, you should see the model in the SageMaker/Models console.

The next step is to define an endpoint configuration. This step is crucial since 
we are defining a model that we want to host and the resources chosen to 
deploy for hosting it. In other words, we are configuring a 
[ProductionVariant](https://docs.aws.amazon.com/sagemaker/latest/APIReference/API_ProductionVariant.html){:target="_blank"} which can take many arguments for defining instance types, 
how to distribute traffic among multiple modes etc. However, we are only 
interested in `ServerlessConfig`.

```python
def create_endpoint_configuration():
    create_endpoint_config_response = sm_client.create_endpoint_config(
        EndpointConfigName="<endpoint-config-name>",
        ProductionVariants=[
            {
                "ModelName": "<model-name>",
                "VariantName": "<variant-name>",
                "ServerlessConfig": {
                    "MemorySizeInMB": 2048,
                    "MaxConcurrency": 1,
                },
            }
        ],
    )
    print(create_endpoint_config_response)
```

SageMaker console has the Endpoint Configurations section where we can confirm 
the configuration.

After configuring the endpoint, we can deploy it. This can take a few minutes. 
SageMaker Client offers the `get_waiter()` method that returns an object that 
can wait for some condition, in this case for an endpoint to be in service.

```python
def create_endpoint():
    create_endpoint_response = sm_client.create_endpoint(
        EndpointName="<endpoint-name>",
        EndpointConfigName="<endpoint-config-name>",
    )
    print("Endpoint Arn: " + create_endpoint_response["EndpointArn"])
    resp = sm_client.describe_endpoint(EndpointName="<endpoint-name>")
    print("Endpoint Status: " + resp["EndpointStatus"])
    print("Waiting for {} endpoint to be in service".format("<endpoint-name>"))
    waiter = sm_client.get_waiter("endpoint_in_service")
    waiter.wait(EndpointName="<endpoint-name>")
```

Finally, we can use the 
[SageMaker Runtime Client](https://boto3.amazonaws.com/v1/documentation/api/latest/reference/services/sagemaker-runtime.html#id2){:target="_blank"} 
for inference and invoking the endpoint.

```python
runtime_sm_client = boto3.client(service_name="sagemaker-runtime")

def invoke_endpoint():
    content_type = "application/json"
    request_body = {}
    payload = json.dumps(request_body)
    response = runtime_sm_client.invoke_endpoint(
        EndpointName="<endpoint-name>",
        ContentType=content_type,
        Body=payload,
    )
    result = json.loads(response["Body"].read().decode())
    print(result)
```

### CDK

The same process of creating a model, an endpoint configuration, and deployment 
of an endpoint can be achieved through a CDK application. 
This is usually a better option since we can manage the infrastructure from 
the code and deploy services as stacks.

In order to use SageMaker constructs we'll need to install 
`@aws-cdk/aws-sagemaker` module. There are L1 Cfn constructs for each service 
that we need to configure: 
[`CfnModel`](https://docs.aws.amazon.com/cdk/api/v1/python/aws_cdk.aws_sagemaker/CfnModel.html){:target="_blank"}, 
[`CfnEndpointConfig`](https://docs.aws.amazon.com/cdk/api/v1/python/aws_cdk.aws_sagemaker/CfnEndpointConfig.html){:target="_blank"}
, and 
[`CfnEndpoint`](https://docs.aws.amazon.com/cdk/api/v1/python/aws_cdk.aws_sagemaker/CfnEndpoint.html){:target="_blank"}.

We will approach this by setting up a CDK application and a separate stack 
construct for SageMaker services.

> Note: If you are not sure how to start with a CDK application, please see 
[Your first AWS CDK app](https://docs.aws.amazon.com/cdk/v2/guide/hello_world.html){:target="_blank"}

The stack will have three methods: 
- `create_model()` - Creates an IAM role and a SageMaker model based on the Docker image name
- `create_endpoint_configuration()` - Creates an endpoint configuration for a specific model
- `create_endpoint()` - Deploys the endpoint based on the provided endpoint configuration

The code below implements a simple example of this stack:

```python
from aws_cdk import core
from aws_cdk.aws_iam import Role, ManagedPolicy, ServicePrincipal
from aws_cdk.aws_sagemaker import CfnModel, CfnEndpointConfig, CfnEndpoint


class SageMakerStack(core.Stack):
    def __init__(
        self,
        scope: core.Construct,
        id_: str,
        env: core.Environment,
    ) -> None:
        super().__init__(scope=scope, id=id_, env=env)
        self.env = env

    def create_model(
        self,
        id_: str,
        model_name: str,
        image_name: str,
    ) -> CfnModel:
        role = Role(
            self,
            id=f"{id_}-SageMakerRole",
            role_name=f"{id_}-SageMakerRole",
            assumed_by=ServicePrincipal("sagemaker.amazonaws.com"),
            managed_policies=[
                ManagedPolicy.from_aws_managed_policy_name("AmazonSageMakerFullAccess")
            ],
        )
        container = CfnModel.ContainerDefinitionProperty(
            container_hostname="<container-hostname>",
            image="{}.dkr.ecr.eu-west-1.amazonaws.com/{}:latest".format(
                self.env.account, image_name
            ),
        )
        return CfnModel(
            self,
            id=f"{id_}-SageMakerModel",
            model_name=model_name,
            execution_role_arn=role.role_arn,
            containers=[container],
        )

    def create_endpoint_configuration(
        self,
        id_: str,
        model_name: str,
        endpoint_configuration_name: str,
    ) -> CfnEndpointConfig:
        return CfnEndpointConfig(
            self,
            id=f"{id_}-SageMakerEndpointConfiguration",
            endpoint_config_name=endpoint_configuration_name,
            production_variants=[
                CfnEndpointConfig.ProductionVariantProperty(
                    model_name=model_name,
                    initial_variant_weight=1.0,
                    variant_name="AllTraffic",
                    serverless_config=CfnEndpointConfig.ServerlessConfigProperty(
                        max_concurrency=1,
                        memory_size_in_mb=2048,
                    ),
                )
            ],
        )

    def create_endpoint(
        self,
        id_: str,
        endpoint_configuration_name: str,
        endpoint_name: str,
    ) -> CfnEndpoint:
        return CfnEndpoint(
            self,
            id=f"{id_}-SageMakerEndpoint",
            endpoint_config_name=endpoint_configuration_name,
            endpoint_name=endpoint_name,
        )
```

Now we can use this stack class to deploy multiple models in one or more stacks.

```python
from aws_cdk import core
from stacks.sagemaker import SageMakerStack


class SimpleExampleApp(core.App):

    def __init__(self) -> None:
        super().__init__()
        env = core.Environment(
            account="<account>",
            region="<region>",
        )

        sagemaker = SageMakerStack(
            scope=self,
            id_="app-sagemaker-stack",
            env=env,
        )
        model = sagemaker.create_model(
            id_="AppModel",
            model_name="<model-name>",
            image_name="<image-name>",
        )
        endpoint_config = sagemaker.create_endpoint_configuration(
            id_="AppEndpointConfiguration",
            model_name="<model-name>",
            endpoint_configuration_name="app-endpoint-configuration",
        )
        endpoint_config.add_depends_on(model)
        endpoint = sagemaker.create_endpoint(
            id_="AppEndpoint",
            endpoint_configuration_name="app-endpoint-configuration",
            endpoint_name="app-endpoint",
        )
        endpoint.add_depends_on(endpoint_config)

simple_app = SimpleExampleApp()
simple_app.synth()
```

Sometimes CDK cannot infer the right order to provision our resources in. 
For example, the creation of endpoint configuration may start before the model 
is defined, which doesn't make sense in this example. That's why we add 
`A.add_depends_on(B)` to each [`CfnResource`](https://docs.aws.amazon.com/cdk/api/v1/python/aws_cdk.core/CfnResource.html#aws_cdk.core.CfnResource){:target="_blank"} and it will inform the CDK 
that the creation of resource `A` should follow the creation of resource `B`. 

Now we can generate CloudFormation templates and deploy custom models for 
serverless inference as stacks that can be easily managed.

> Note: If you also want to manage Docker images through AWS CDK, 
please take a look at 
[AWS CDK Docker Image Assets](https://docs.aws.amazon.com/cdk/api/v1/python/aws_cdk.aws_ecr_assets/README.html){:target="_blank"}. 
However, this approach will publish image assets to the CDK-controlled 
ECR repository. To publish Docker images to an ECR repository in your 
control, please see 
[cdk-ecr-deployment](https://github.com/cdklabs/cdk-ecr-deployment){:target="_blank"}.

## Final Words

I hope that this article gave you a better understanding of how to implement a 
custom model using the SageMaker and deploy it for the serverless inference. 
The main key concepts here are the configuration of a custom Docker image 
and connection between a model, an endpoint configuration, and an endpoint.

The code examples are deliberately simplified and serve only to introduce the 
key concepts and ideas. For more information and examples please check out the 
official AWS repository for 
[Advanced SageMaker Functionality Examples](https://github.com/aws/amazon-sagemaker-examples/tree/main/advanced_functionality){:target="_blank"}.

If you have any questions or suggestions, please reach out, I'm always 
available.

## Resources

- [AWS Docs - Using Docker containers with SageMaker](https://docs.aws.amazon.com/sagemaker/latest/dg/docker-containers.html){:target="_blank"}
- [AWS Docs - Use Your Own Inference Code with Hosting Services](https://docs.aws.amazon.com/sagemaker/latest/dg/your-algorithms-inference-code.html){:target="_blank"}
- [AWS Docs - SageMaker Roles](https://docs.aws.amazon.com/sagemaker/latest/dg/sagemaker-roles.html){:target="_blank"}
- [Amazon SageMaker Multi-Model Endpoints using your own algorithm container](https://sagemaker-examples.readthedocs.io/en/latest/advanced_functionality/multi_model_bring_your_own/multi_model_endpoint_bring_your_own.html){:target="_blank"}
- [Bring Your Own Container With Amazon SageMaker](https://towardsdatascience.com/bring-your-own-container-with-amazon-sagemaker-37211d8412f4){:target="_blank"}
- [Advanced Amazon SageMaker Functionality Examples](https://github.com/aws/amazon-sagemaker-examples/tree/main/advanced_functionality){:target="_blank"}