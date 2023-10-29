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


### Step 3: Download and install a PostgreSQL Client
To connect to your Aurora PostgreSQL database instance, you need to download and install a PostgreSQL client. You can use any preferred client, such as [pgAdmin](https://www.pgadmin.org/download/) or [SQL Workbench](https://aws.amazon.com/getting-started/tutorials/create-connect-postgresql-db/). The tutorial provides instructions for downloading and installing the pgAdmin client. Note that the client must be run on the same device and network where you created the DB instance, and the database security group is configured to allow connection only from that device. Once you have installed the client, you can proceed to Step 4.

### Step 4: Connect to the Aurora DB instance
In this step, you use the pgAdmin 4 PostgreSQL Client to connect to the Aurora PostgreSQL DB instance. You start the client, add a new server named TutorialServer, and enter the database cluster endpoint and password. Then, you expand the TutorialServer navigation tree and open a query tool to run queries against your DB instance.

### Step 5: Query database with Amazon Comprehend
In this step, you install extensions for machine learning and Amazon S3 access. Then, you set up and query a sample table. Finally, you load sample data from a customer review dataset and run queries on the customer reviews for sentiment analysis and confidence.

In the query editor, run the following statement to install the Amazon ML services extension for model inference.
```
CREATE EXTENSION IF NOT EXISTS aws_ml CASCADE;
```

Run the following statement to create your sample table named comments.
```
CREATE TABLE IF NOT EXISTS comments (
    comment_id serial PRIMARY KEY, 
    comment_text VARCHAR(255) NOT NULL
);
```

 Add data to your comments table using the following statement.
 ```
INSERT INTO comments (comment_text)
VALUES ('This is very useful, thank you for writing it!');
INSERT INTO comments (comment_text)
VALUES ('Awesome, I was waiting for this feature.');
INSERT INTO comments (comment_text)
VALUES ('An interesting write up, please add more details.');
INSERT INTO comments (comment_text)
VALUES ('I do not like how this was implemented.');
```

Run the following statement to call the aws_comprehend.detect sentiment function.
```
SELECT * FROM comments, aws_comprehend.detect_sentiment(comments.comment_text, 'en') as s
```

Run the following statement to install the Amazon S3 service extension. This extension allows you to load data from Amazon S3 into the Aurora DB instance from SQL.
```
CREATE EXTENSION IF NOT EXISTS aws_s3 CASCADE;
```

Copy and paste the following code to create your table named review_simple.
```
create table review_simple
    (
        marketplace char(2),
        customer_id varchar(20),
        review_id varchar(20) primary key,
        product_id varchar(20),
        product_parent varchar(20),
        product_title text,
        product_category varchar(20),
        star_rating int,
        helpful_votes int,
        total_votes int,
        vine char,
        verified_purchase char,
        review_headline varchar(255),
        review_body text,
        review_date date,
        scored_sentiment varchar(20),
        scored_confidence float4
)
```

Run the following statement to load the data directly from Aurora PostgreSQL.

Note: In production, you may choose to use AWS Glue or another ETL process to load the data.
```
select aws_s3.table_import_from_s3(
   'review_simple', 'marketplace,  customer_id,review_id,product_id, 
    product_parent, product_title, product_category, star_rating,  
    helpful_votes, total_votes, vine, verified_purchase,review_headline,    
    review_body, review_date',
    '(FORMAT CSV, HEADER true, DELIMITER E''\t'', QUOTE ''|'')',
    'amazon-reviews-pds',
    'tsv/sample_us.tsv',
    'us-east-1'
)
```

When you loaded the data, the scored_sentiment and scored_confidence columns in the table were ignored; the data set loaded from S3 didn’t contain those columns. Now, you'll use Comprehend to evaluate the sentiment, and use the result to update those columns in the table. Run the following statement to call Comprehend and update the table.
```
update review_simple
   set scored_sentiment = s.sentiment, scored_confidence = s.confidence
  from review_simple as src, 
       aws_comprehend.detect_sentiment( src.review_body, 'en') as s
 where src.review_id = review_simple.review_id
   and src.scored_sentiment is null
```
 Run the following statement to see the returned data.
 ```
 select customer_id, review_id, review_body, scored_sentiment, scored_confidence from review_simple
```

Run the following statement to see the data summarized based on the sentiment returned by Comprehend.
```
select scored_sentiment,count(*) as nReviews from review_simple group by scored_sentiment
```
Run the following statement to query the data based on a confidence threshold of > .9.

```
select scored_sentiment,count(*) as nReviews from review_simple where scored_confidence > .9
group by scored_sentiment 
```
In this query, you're leveraging the score sentiment and confidence values you saved in the table. This is an example of the flexibility and performance gained by saving the sentiment directly in the database. The ability to do this directly in the database can give individuals more comfortable with SQL easier access to the data.

## Conclusion
Amazon Aurora machine learning provides an easy and efficient way to integrate machine learning capabilities into your applications without having prior machine learning experience or building custom integrations. By following this tutorial, you learned how to create an Aurora PostgreSQL database instance, integrate with Amazon Comprehend for sentiment analysis, and analyze sentiments of records in the database table using a customer reviews dataset.

With Aurora machine learning, developers can run low-latency, real-time use cases such as fraud detection, ad targeting, and product recommendations by calling Amazon SageMaker or Amazon Comprehend for a wide variety of ML algorithms directly from Aurora.

We hope this tutorial has been helpful in getting started with Aurora machine learning and exploring its capabilities. Please feel free to provide feedback and suggestions for improving this tutorial.


## License & Credits
This project is based on the AWS Hands-on Project tutorial called [Perform sentiment analysis with Amazon Aurora ML integration](https://aws.amazon.com/it/getting-started/hands-on/sentiment-analysis-amazon-aurora-ml-integration/?trk=gs_card) available on [AWS Hands-on official resurces](https://aws.amazon.com/it/getting-started/hands-on/) . 

[![MIT License](https://img.shields.io/badge/license-MIT-blue)](https://opensource.org/license/mit/)


## Contributors

[Daniele Bocchino](https://danielebocchino.github.io/)

[![GitHub Followers](https://img.shields.io/github/followers/DanieleBocchino?style=social)](https://github.com/DanieleBocchino)  
[![LinkedIn Connect](https://img.shields.io/badge/LinkedIn-Connect-blue?style=social&logo=linkedin)](https://www.linkedin.com/in/daniele-bocchino-aa602a20b/)