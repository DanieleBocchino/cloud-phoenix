# Cloud Phoenix Kata

[![GitHub Issues](https://img.shields.io/github/issues/DanieleBocchino/cloud-phoenix)](https://github.com/DanieleBocchino/cloud-phoenix)
[![GitHub Stars](https://img.shields.io/github/stars/DanieleBocchino/cloud-phoenix)](https://github.com/DanieleBocchino/cloud-phoenix)
[![GitHub Forks](https://img.shields.io/github/forks/DanieleBocchino/cloud-phoenix)](https://github.com/DanieleBocchino/cloud-phoenix)
[![GitHub Contributors](https://img.shields.io/github/contributors/DanieleBocchino/cloud-phoenix)](https://github.com/DanieleBocchino/cloud-phoenix)
[![GitHub Last Commit](https://img.shields.io/github/last-commit/DanieleBocchino/cloud-phoenix)](https://github.com/DanieleBocchino/cloud-phoenix)

"This project aims to create an infrastructure for the Phoenix Application. The infrastructure should be created using IaC (Infrastructure as Code), and for this, I've decided to use Terraform

## Table of Contents

- [Project Overview](#projectoverview)
- [Steps](#steps)
- [Conclusion](#conclusion)
- [License & Credits](#license&credits)
- [Contributors](#contributors)


## Project Overview

For this project, I've already cloned the Phoenix Application, which is a Node.js application. My goal is to create an infrastructure composed of a Node.js server and a MongoDB database, and to manage two features that were introduced during development:

- GET /crash kills the application process
- GET /generatecert is not optimized and creates resource consumption peaks

Additionally, it is also necessary to address the following issues:

- **Automate the Infrastructure Creation:** Automate the creation of the infrastructure and the setup of the application.

- **Crash Recovery:** Implement a method to auto-restart the service if it crashes.

- **Backup and Rotation**: Backup the logs and database with a rotation policy of 7 days.

- **CPU Peak Notification:** Send a notification for any CPU peak events.

- **CI/CD Pipeline:** Implement a Continuous Integration and Continuous Deployment (CI/CD) pipeline for the code.

- **Auto-Scaling:** Scale the infrastructure when the number of requests exceeds 100 requests per minute.




To successfully complete this project, I have utilized various Amazon Web Services (AWS). Specifically, I have employed the following services:

- **ECS Fargate:** Used for running the Node.js server. ECS Fargate abstracts the underlying infrastructure, allowing for more focus on application development.

- **ECR (Elastic Container Registry):** Utilized for storing the Docker images of the Node.js application. ECR provides a secure and scalable environment for container image storage.

- **MongoDB on ECS:** Deployed for the database requirements. Using MongoDB on ECS offers the benefit of high availability and easy scaling.

- **Load Balancer:** Incorporated to distribute incoming application traffic across multiple targets, such as ECS instances. This is crucial for ensuring high availability and fault tolerance, especially when the number of requests exceeds 100 per minute, as stated in the problem requirements.

- **CloudWatch, Lambda, and SNS:** These are employed to monitor the system and send notifications in the event of CPU peak usage. CloudWatch observes system performance, Lambda processes the data and triggers an SNS notification.

- **Auto Scaling:** Implemented to automatically adjust the number of server instances in response to changing traffic loads. This is especially useful when the number of requests increases beyond a specific threshold.

- **Backup Solutions:** Utilized for database backup with a 7-day rotation policy. This ensures data durability and aids in disaster recovery.

- **CodeCommit, CodePipeline, and CodeBuild:** These services are used to set up a CI/CD (Continuous Integration/Continuous Deployment) pipeline for building and deploying the Node.js Docker image."

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
    ```
4. **Initialize Terraform**: Execute `terraform init` in the directory containing your `main.tf` to download necessary plugins.
  
5. **Validate Configuration**: Use `terraform validate` to ensure your configuration is valid.

6. **Test Run**: Perform `terraform plan` to preview the changes.


### Step 2: ECS Fargate Setup

1. **Create ECS Cluster**: Define the ECS cluster resources in Terraform. 
    - Refer to [ecs.tf](#ecs.tf) for the implementation.

 
2. **Task Definition**: Create the ECS task definition for the Node.js app specifying CPU, memory, and Docker image from ECR.
    - Code snippet can be found in [ecs.tf](#ecs.tf).

3. **Service Definition**: Create the ECS service to run the defined tasks.
    - Refer to [ecs.tf](ecs.tf).

4. **Network Configuration**: Set up the VPC, subnets, and security groups.
    - See [vpc.tf](#vpc.tf) for this configuration.

5. **Deploy Changes**: Run `terraform apply` to apply the configurations.

6. **Verify Setup**: Confirm the ECS tasks are running as expected either through AWS Console or AWS CLI.


### Step 3: ECR Setup

1. **Create ECR Repository**: Define an Amazon ECR (Elastic Container Registry) where you'll store your Docker images.
    - Refer to [ecr.tf](#ecr.tf) for the Terraform configuration.

2. **Authenticate Docker with ECR**: Use the AWS CLI to authenticate your Docker client to the Amazon ECR registry to which you intend to push your image.
  

3. **Build Docker Image**: Build your Docker image locally, ensuring it matches the specifications required for the application.


4. **Push to ECR**: After building the image, push it to the ECR repository.


5. **Update ECS Task Definition**: Make sure your ECS task definition is set to use the Docker image from the ECR repository. This should be configured in the ECS task definition within [ecs.tf](#ecs.tf).


---

### Step 4: ECS MongoDB Setup

1. **Create ECS MongoDB Cluster**: Just like you did for the Node.js application, define an ECS cluster specifically for MongoDB.
    - Refer to [ecs_mongo.tf](#link-to-ecs_mongo.tf) for the Terraform configuration.


2. **MongoDB Task Definition**: Create an ECS task definition for MongoDB. Specify the CPU, memory, and Docker image (either from ECR or Docker Hub).
    - This should be included in [ecs_mongo.tf](#ecs_mongo.tf).


3. **Service Definition**: Create an ECS service to manage the MongoDB tasks. Set up necessary configurations like desired count, placement strategies, etc.
    - Refer to [ecs_mongo.tf](#ecs_mongo.tf).

4. **Security and Network**: Define security groups and network configurations specific to MongoDB. These should allow traffic only on MongoDB's port (typically 27017).
    - This information should be in [vpc.tf](#vpc.tf).

5. **Data Volume**: Optionally, define an EBS volume to persist MongoDB data and attach it to the ECS task definition.
    - This can also be included in [ecs_mongo.tf](#ecs_mongo.tf).


6. **Deploy and Verify**: Use `terraform apply` to deploy these configurations. Check the


## Conclusion


## License & Credits 
[![MIT License](https://img.shields.io/badge/license-MIT-blue)](https://opensource.org/license/mit/)


## Contributors

[Daniele Bocchino](https://danielebocchino.github.io/)

[![GitHub Followers](https://img.shields.io/github/followers/DanieleBocchino?style=social)](https://github.com/DanieleBocchino)  
[![LinkedIn Connect](https://img.shields.io/badge/LinkedIn-Connect-blue?style=social&logo=linkedin)](https://www.linkedin.com/in/daniele-bocchino-aa602a20b/)