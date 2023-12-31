# Cloud Phoenix Kata - Challenge

[![GitHub Issues](https://img.shields.io/github/issues/DanieleBocchino/cloud-phoenix)](https://github.com/DanieleBocchino/cloud-phoenix)
[![GitHub Stars](https://img.shields.io/github/stars/DanieleBocchino/cloud-phoenix)](https://github.com/DanieleBocchino/cloud-phoenix)
[![GitHub Forks](https://img.shields.io/github/forks/DanieleBocchino/cloud-phoenix)](https://github.com/DanieleBocchino/cloud-phoenix)
[![GitHub Contributors](https://img.shields.io/github/contributors/DanieleBocchino/cloud-phoenix)](https://github.com/DanieleBocchino/cloud-phoenix)
[![GitHub Last Commit](https://img.shields.io/github/last-commit/DanieleBocchino/cloud-phoenix)](https://github.com/DanieleBocchino/cloud-phoenix)

This project aims to create an infrastructure for the Phoenix Application. The infrastructure should be created using IaC (Infrastructure as Code), and for this, I've decided to use Terraform

### Table of Contents

1. [Project Overview](#project-overview)
2. [AWS Services Employed](#aws-services-employed)
3. [Steps](#steps)
    - [Step 1: Initial Setup](#step-1-initial-setup)
    -  [Step 2: VPC](#step-2-vpc)
    - [Step 3: ECS and Fargate](#step-3-ecs-and-fargate)
    - [Step 4: ECR](#step-4-ecr)
    - [Step 5: Application Load Balancer](#step-5-application-load-balancer)
    - [Step 6: Auto-Scaling](#step-6-auto-scaling)
        - [ECS_Target](#ecs_target)
        - [Scale_up_policy](#scale_up_policy)
        - [CloudWatch](#cloudwatch)
    - [Step 7: Document DB](#document-db)
    - [Step 8: AWS Backup](#document-db)
    - [Step 9: CI/CD](#step-7-cicd)
        - [BuildSpec](#buildspec)
        - [Pipeline](#pipeline)
    - [Step 10: CloudWatch and SNS for Notifications](#step-10-cloudwatch-and-sns-for-notifications)
4. [Deploy and Verify](#deploy-and-verify)
5. [License & Credits](#license&credits)
6. [Contributors](#contributors)

## Project Overview
In this project, the focus is on automating the infrastructure for the Phoenix Application—a Node.js-based application. My goal is to create an infrastructure composed of a Node.js server and a MongoDB database, and to manage two features that were introduced during development:


```bash
- GET /crash kills the application process
- GET /generatecert is not optimized and creates resource consumption peaks
```

Moreover, additional operational challenges need to be addressed, such as:


- **Automate the Infrastructure Creation:** Automate the creation of the infrastructure and the setup of the application.

- **Crash Recovery:** Implement a method to auto-restart the service if it crashes.

- **Backup and Rotation**: Backup the logs and database with a rotation policy of 7 days.

- **CPU Peak Notification:** Send a notification for any CPU peak events.

- **CI/CD Pipeline:** Implement a Continuous Integration and Continuous Deployment (CI/CD) pipeline for the code.

- **Auto-Scaling:** Scale the infrastructure when the number of requests exceeds 100 requests per minute.


### AWS Services Employed


To successfully complete this project, I have utilized various Amazon Web Services (AWS). Specifically, I have employed the following services:

- **ECS Fargate:** Used for running the Node.js server. ECS Fargate abstracts the underlying infrastructure, allowing for more focus on application development.

- **ECR (Elastic Container Registry):** Utilized for storing the Docker images of the Node.js application. ECR provides a secure and scalable environment for container image storage.

- **MongoDB on DocumentDB:** Deployed for the database requirements. Using MongoDB on DocumentDB offers the benefit of high availability and easy scaling.

- **Load Balancer:** Incorporated to distribute incoming application traffic across multiple targets, such as ECS instances. This is crucial for ensuring high availability and fault tolerance, especially when the number of requests exceeds 100 per minute, as stated in the problem requirements.

- **CloudWatch  and SNS:** These are employed to monitor the system and send notifications in the event of CPU peak usage. CloudWatch observes system performance and triggers an SNS notification.

- **Auto Scaling:** Implemented to automatically adjust the number of server instances in response to changing traffic loads. This is especially useful when the number of requests increases beyond a specific threshold.

- **Backup Solutions:** Utilized for database backup with a 7-day rotation policy. This ensures data durability and aids in disaster recovery.

- **CodeCommit, CodePipeline, and CodeBuild:** These services are used to set up a CI/CD (Continuous Integration/Continuous Deployment) pipeline for building and deploying the Node.js Docker image.

Below is the architecture diagram presented

<p align="center">
<img src="./assets/schema.png" alt="schema" align="center">
</p>


## Steps

### Step 1: Initialization

1. **Install Dependencies**: Ensure Terraform and AWS CLI are installed on your machine.
    - **Terraform**
    - **AWS CLI**

2. **AWS Credentials**: Configure AWS credentials by setting environment variables (`AWS_ACCESS_KEY_ID` and `AWS_SECRET_ACCESS_KEY`) or running `aws configure`.

3. **Create `.tfvars` File**: Create a `.tfvars` file to store sensitive variables.

    ```hcl
    # variables.tfvars

    aws_account_id     = ""
    github_oauthtoken  = ""
    alert_email        = ""
    db_password        = ""
    db_username        = ""
    email              = ""
    port               = 3000
    ```
4. **Initialize Terraform**: Execute `terraform init` in the directory containing your `main.tf` to download necessary plugins.
  
5. **Validate Configuration**: Use `terraform validate` to ensure your configuration is valid.

6. **Test Run**: Perform `terraform plan` to preview the changes.


### Step 2: VPC Configuration

In this step, I leveraged a Terraform module to define the Virtual Private Cloud (VPC) as well as the associated subnets.

By utilizing this module, we can streamline the process of VPC creation, ensuring a more efficient and error-free setup. This encapsulates the necessary configurations for both the VPC and its subnets, providing a robust foundation for the subsequent steps in this infrastructure setup. 

```bash
module "vpc" {
    source = "terraform-aws-modules/vpc/aws"

    name = "phoenix-vpc"
    cidr = "10.0.0.0/16"

    azs             = ["us-east-1a", "us-east-1b", "us-east-1c"]
    private_subnets = ["10.0.1.0/24", "10.0.2.0/24", "10.0.3.0/24"]
    public_subnets  = ["10.0.101.0/24", "10.0.102.0/24", "10.0.103.0/24"]

    enable_nat_gateway = true
    enable_vpn_gateway = true

    tags = {
        Terraform   = "true"
        Environment = "prod"
    }
}

```

### Step 3: ECS Fargate Setup

1. **Create ECS Cluster**: Define the ECS cluster resources in Terraform. 

    ```bash
    resource "aws_ecs_cluster" "phoenix_cluster" {
        name = "phoenix-cluster"
    } 
    ```

2. **Task Definition**: Create the ECS task definition for the Node.js app specifying CPU, memory, and Docker image from ECR.
        
    ```py
    resource "aws_ecs_task_definition" "phoenix_task" {
    family                   = "phoenix-service"
    network_mode             = "awsvpc"
    requires_compatibilities = ["FARGATE"]
    cpu                      = "256"
    memory                   = "512"
    execution_role_arn       = aws_iam_role.ecs_execution_role.arn

    container_definitions = jsonencode([{
        name  = "phoenix-container"
        image = "${aws_ecr_repository.phoenix_repository.repository_url}:latest"
        portMappings = [{
            containerPort = var.port
            hostPort      = var.port
        }]

        logConfiguration = {
            logDriver = "awslogs"
            options = {
                awslogs-group  = "/ecs/phoenix-service"
                awslogs-region = "us-east-1"
                awslogs-stream-prefix = "ecs"
            }
        }

        environment = [
            {
                name  = "DB_CONNECTION_STRING",
                value = "mongodb://${var.db_username}:${var.db_password}@${aws_docdb_cluster.db_phoenix_cluster.endpoint}:${aws_docdb_cluster.db_phoenix_cluster.port}/?replicaSet=rs0&readPreference=secondaryPreferred&retryWrites=false"
            }
        ]
    }])
    }
    ```


3. **Service Definition**: Create the ECS service to run the defined tasks.
    ``` bash
    resource "aws_ecs_service" "phoenix_service" {
        name            = "phoenix-service"
        cluster         = aws_ecs_cluster.phoenix_cluster.id
        task_definition = aws_ecs_task_definition.phoenix_task.arn
        launch_type     = "FARGATE"
        network_configuration {
            subnets         = module.vpc.private_subnets
            security_groups = [aws_security_group.documentdb_sg.id, aws_security_group.ecs_sg.id]
        }
        desired_count = 1
        load_balancer {
            target_group_arn = aws_lb_target_group.phoenix_target_group.arn
            container_name   = "phoenix-container"
            container_port   = var.port
        }
    }
    ```

### Step 4: ECR Setup

1. **Create ECR Repository**: Define an Amazon ECR (Elastic Container Registry) where you'll store your Docker images. 

    ``` bash
    resource "aws_ecr_repository" "phoenix_repository" {
    name                 = "phoenix-repository"
    image_tag_mutability = "MUTABLE"
    }
    ```



2. **Authenticate Docker with ECR**: Use the AWS CLI to authenticate your Docker client to the Amazon ECR registry to which you intend to push your image.
    ``` bash
    aws ecr get-login-password --region <region> | docker login --username AWS --password-stdin <account_id>.dkr.ecr.<region>.amazonaws.com
    ``` 

3. **Build Docker Image**: Build your Docker image locally, ensuring it matches the specifications required for the application.
    ``` bash
    docker build -t <image_name> .
    ```

4. **Push to ECR**: After building the image, push it to the ECR repository.
    ``` bash
    docker push  <accound_id>.dkr.ecr.<region>.amazonaws.com/image_name>:latest
    ```


### Step 5: Application Load Balancer

In this phase, an Application Load Balancer (ALB) is deployed to manage incoming application traffic and distribute it evenly across multiple targets, such as Amazon ECS instances, which are located in multiple Availability Zones. This ensures high availability and fault tolerance for the Phoenix application. Below are the key components involved in setting up the ALB: 

1. **Create Balancer**
The first step involves creating the Application Load Balancer itself within the specified Virtual Private Cloud (VPC). 

    ```bash
    resource "aws_lb" "phoenix_alb" {
        name               = "phoenix-alb"
        internal           = false
        load_balancer_type = "application"
        security_groups    = [aws_security_group.ecs_sg.id]
        subnets            = module.vpc.public_subnets

        enable_deletion_protection = false
    }
    ```

2. **Create Target Group**
The Target Group is a collection of resources (usually ECS instances) that the ALB will distribute incoming traffic to
    ```bash
    resource "aws_lb_target_group" "phoenix_target_group" {
        name        = "phoenix-target-group"
        port        = var.port
        protocol    = "HTTP"
        vpc_id      = module.vpc.vpc_id
        target_type = "ip"
    }
    ```
3. **Create Listener**
Listeners check for incoming connection requests, based on the protocol and port you specify, and route the request to one of the target groups.

    ```bash
    resource "aws_lb_listener" "phoenix_listener" {
        load_balancer_arn = aws_lb.phoenix_alb.arn
        port              = 80
        protocol          = "HTTP"

        default_action {
            type             = "forward"
            target_group_arn = aws_lb_target_group.phoenix_target_group.arn
        }
    }
    ```

### Step 6: AustoScaling Group
To ensure our application scales effectively, especially when the number of requests exceeds 100 requests per minute, we implement an auto-scaling configuration. This configuration is done using AWS services and Terraform. The primary components are:

1. **ECS_Target**
 serves as the focal point for auto-scaling actions. It specifies the ECS service that needs to be scaled. The minimum and maximum capacity for the ECS service are also defined here.

    ```bash
    resource "aws_appautoscaling_target" "ecs_target" {
        max_capacity       = 10
        min_capacity       = 1
        resource_id        = "service/${aws_ecs_cluster.phoenix_cluster.name}/${aws_ecs_service.phoenix_service.name}"
        scalable_dimension = "ecs:service:DesiredCount"
        service_namespace  = "ecs"
    }

    ```

2. **Scale up policy**
 is responsible for defining how the scaling should happen. It utilizes the CloudWatch alarm to determine when to scale in or scale out.
    ```bash
        resource "aws_appautoscaling_policy" "scale_up_policy" {
            name               = "scale-up"
            policy_type        = "StepScaling"
            resource_id        = aws_appautoscaling_target.ecs_target.resource_id
            scalable_dimension = aws_appautoscaling_target.ecs_target.scalable_dimension
            service_namespace  = aws_appautoscaling_target.ecs_target.service_namespace

            step_scaling_policy_configuration {
                adjustment_type         = "ChangeInCapacity"
                cooldown                = 300
                metric_aggregation_type = "Average"

                step_adjustment {
                metric_interval_lower_bound = 0
                scaling_adjustment          = 1
                }
            }

            depends_on = [aws_cloudwatch_metric_alarm.request_count_alarm]
        }
    ```
3. **CloudWatch**
is employed to monitor the system and trigger the scaling policy. We set up a CloudWatch metric alarm that observes the RequestCountPerTarget metric from the Application Load Balancer. If the alarm detects that the rate exceeds 100 requests per minute,.

    ```bash
    resource "aws_cloudwatch_metric_alarm" "request_count_alarm" {
        alarm_name          = "high-request-count-alarm"
        comparison_operator = "GreaterThanOrEqualToThreshold"
        evaluation_periods  = "1"
        metric_name         = "RequestCountPerTarget"
        namespace           = "AWS/ApplicationELB"
        period              = "60"
        statistic           = "Sum"
        threshold           = "100"
        alarm_description   = "This alarm fires when the request rate reaches 100 req/min"
        alarm_actions       = [aws_appautoscaling_policy.scale_up_policy.arn]
    }
    ```


### Step 7: Document DB
In this step, we integrate Amazon DocumentDB to fulfill our database requirements. Amazon DocumentDB is a fully managed database service that offers MongoDB compatibility, high availability, and easy scaling

```bash
    resource "aws_docdb_cluster" "db_phoenix_cluster" {
        cluster_identifier      = "db-phoenix-cluster"
        engine                  = "docdb"
        master_username         = var.db_username
        master_password         = var.db_password
        db_subnet_group_name    = aws_docdb_subnet_group.phoenix_subnet_group.name
        skip_final_snapshot     = true
        vpc_security_group_ids  = [aws_security_group.documentdb_sg.id]
        backup_retention_period = 7
        port                    = 27017
    }
```

### Step 8: AWS Backup
In the Phoenix application project, AWS Backup is specifically used for managing backups of our Amazon DocumentDB database. The adoption of AWS Backup was a strategic choice to ensure security, reliability, and compliance throughout the data lifecycle.

```bash
    resource "aws_backup_vault" "phoenix_vault" {
        name = "phoenix-vault"
    }

    resource "aws_backup_plan" "phoenix_backup_plan" {
        name = "phoenix-backup-plan"

        rule {
            rule_name         = "phoenix-rule"
            target_vault_name = aws_backup_vault.phoenix_vault.name
            schedule          = "cron(0 12 * * ? *)"
        }
    }

    resource "aws_backup_selection" "phoenix_backup_selection" {
        iam_role_arn = aws_iam_role.phoenix_backup_role.arn
        name         = "phoenix-backup-selection"
        plan_id      = aws_backup_plan.phoenix_backup_plan.id

        resources = [
            aws_docdb_cluster.db_phoenix_cluster.arn,
        ]
    }
```


### Step 9: CI/CD
Continuous Integration and Continuous Deployment (CI/CD) play a crucial role in automating the software development process. For this project, we focus on CI/CD steps that allow us to automatically build a Docker image, push it to Amazon's Elastic Container Registry (ECR), and deploy it to ECS (Elastic Container Service)

1. **Buildspec.yml**
file serves as the recipe for CodeBuild. It contains the sequence of commands which CodeBuild will execute. These commands can range from code compilation, running tests, to building Docker images.

``` yaml
version: 0.2


phases:
  pre_build:
    commands:
      - echo Logging in to Amazon ECR...
      - aws ecr get-login-password --region $AWS_DEFAULT_REGION | docker login --username AWS --password-stdin $ECR_URL
  build:
    commands:
      - echo Build started on `date`
      - echo Building the Docker image...
      - docker build -t $REPOSITORY_NAME .
      - docker tag $REPOSITORY_NAME:latest $ECR_URL:latest
  post_build:
    commands:
      - echo Build completed on `date`
      - echo Pushing the Docker image...
      - docker push $ECR_URL:latest
      - echo Generating imagedefinitions.json...
      - echo '[{"name":"phoenix-container","imageUri":"'$ECR_URL:latest'"}]' > imagedefinitions.json

artifacts:
  files: imagedefinitions.json
```

2. **Pipeline**
The pipeline is orchestrated using AWS CodePipeline and is configured to automatically trigger whenever there is a new code commit. The pipeline consists of the following stages:

- **Source Stage:** Pulls the latest code from CodeCommit.
- **Build Stage:** Executes CodeBuild, which follows the buildspec.yml for build instructions.
- **Deploy Stage:** Deploys the built Docker image to ECS.
Here is how you can define the pipeline in Terraform:


### Step 10: Monitoring and Notifications with CloudWatch and SNS
AWS CloudWatch and Simple Notification Service (SNS) are used in conjunction to monitor system performance and to send alerts in case of any anomalies. This approach ensures that you are immediately notified of any CPU peak usage, allowing you to take timely actions.

1. **CloudWatch**
AWS CloudWatch is used to collect and track metrics, collect and monitor log files, and set alarms. We have set up alarms for:

- CPU Utilization above a certain threshold.
- Memory Utilization above a certain threshold.

``` bash
resource "aws_cloudwatch_metric_alarm" "high_request_rate" {
  alarm_name          = "high-request-rate"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = "1"
  metric_name         = "YourCustomRequestMetric"
  namespace           = "YourCustomNamespace"
  period              = "60"
  statistic           = "SampleCount"
  threshold           = "100"
  alarm_description   = "This metric triggers when there are more than 100 requests per minute."
  alarm_actions       = [aws_appautoscaling_policy.scale_up_policy.arn]
}
```
2. **SNS (Simple Notification Service)**
AWS SNS is a fully managed messaging service that is set up to receive notifications from CloudWatch. When an alarm is triggered in CloudWatch, a message is sent to an SNS Topic which, in turn, sends notifications through configured protocols like email.

``` bash
resource "aws_sns_topic_subscription" "cpu_alerts_email" {
  topic_arn = aws_sns_topic.cpu_alerts.arn
  protocol  = "email"
  endpoint  = var.alert_email
}
```

### Final Steps: Deployment and Verification with Terraform
After completing the setup, it's crucial to validate your infrastructure. You can deploy and confirm the configurations using the following Terraform commands:

- **Validation**: Use `terraform validate`to ensure the configurations are syntactically correct and internally consistent.

- **Review Changes**: Use `terraform plan`  to preview the changes that will be made to your infrastructure.

- **Execute Deployment**: Use `terraform apply`  to actually apply the desired changes to your infrastructure.



## License & Credits 
[![MIT License](https://img.shields.io/badge/license-MIT-blue)](https://opensource.org/license/mit/)


## Contributors

[Daniele Bocchino](https://danielebocchino.github.io/)

[![GitHub Followers](https://img.shields.io/github/followers/DanieleBocchino?style=social)](https://github.com/DanieleBocchino)  
[![LinkedIn Connect](https://img.shields.io/badge/LinkedIn-Connect-blue?style=social&logo=linkedin)](https://www.linkedin.com/in/daniele-bocchino-aa602a20b/)