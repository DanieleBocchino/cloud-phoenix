# ECS Cluster
resource "aws_ecs_cluster" "phoenix_cluster" {
  name = "phoenix-cluster"
}

# __________________________________ ECS NODE JS ___________________________________________

# ECS Service for Phoenix
resource "aws_ecs_service" "phoenix_service" {
  name            = "phoenix-service"
  cluster         = aws_ecs_cluster.phoenix_cluster.id
  task_definition = aws_ecs_task_definition.phoenix_task.arn
  launch_type     = "FARGATE"
  network_configuration {
    subnets         = module.vpc.private_subnets
    security_groups = [aws_security_group.ecs_sg.id]
  }
  desired_count = 1
  load_balancer {
    target_group_arn = aws_lb_target_group.phoenix_target_group.arn
    container_name   = "phoenix-container"
    container_port   = 3000
  }
}

# ECS Task Definition for Phoenix
resource "aws_ecs_task_definition" "phoenix_task" {
  family                   = "phoenix-task"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = "256"
  memory                   = "512"
  execution_role_arn       = aws_iam_role.ecs_execution_role.arn
  task_role_arn            = aws_iam_role.ecs_task_role.arn


  container_definitions = jsonencode([{
    name  = "phoenix-container"
    image = "${aws_ecr_repository.phoenix_repository.repository_url}:latest"
    healthCheck = {
      command  = ["CMD-SHELL", "curl -f http://localhost:3000/health || exit 1"]
      interval = 30
      timeout  = 5
      retries  = 3
    }
    portMappings = [{
      containerPort = 3000
      hostPort      = 3000
    }]

    environment = [
      {
        name  = "PORT",
        value = "3000"
      },
      {
        name  = "DB_CONNECTION_STRING",
        value = "mongodb://${var.db_username}:${var.db_password}@mongodb-service:27017/phoenix-mongo-db"
      }
    ]
  }])
}



# __________________________________ ECS MONGO DB ___________________________________________

# ECS Task Definition for MongoDB
resource "aws_ecs_task_definition" "mongodb_task" {
  family                   = "mongodb-service"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = "512"
  memory                   = "1024"
  execution_role_arn       = aws_iam_role.ecs_execution_role.arn

  container_definitions = jsonencode([{
    name  = "mongodb-container"
    image = "mongo:4.4"

    entryPoint = ["/bin/sh", "-c"]
    command    = ["mongodump --uri=$DB_CONNECTION_STRING && aws s3 cp /dump s3://phoenix-mongodb-backup-bucket/"]

    logConfiguration = {
      logDriver = "awslogs"
      options = {
        awslogs-group         = aws_cloudwatch_log_group.mongodb_log_group.name
        awslogs-region        = var.aws_region
        awslogs-stream-prefix = "mongodb"
      }
    }

    portMappings = [{
      containerPort = 27017
      hostPort      = 27017
    }]
    environment = [
      {
        name  = "MONGO_INITDB_ROOT_USERNAME",
        value = var.db_username
      },
      {
        name  = "MONGO_INITDB_ROOT_PASSWORD",
        value = var.db_password
      }
    ]
  }])
}


# ECS Service for MongoDB
resource "aws_ecs_service" "mongodb_service" {
  name            = "mongodb-service"
  cluster         = aws_ecs_cluster.phoenix_cluster.id
  task_definition = aws_ecs_task_definition.mongodb_task.arn
  launch_type     = "FARGATE"
  network_configuration {
    subnets         = module.vpc.private_subnets
    security_groups = [aws_security_group.ecs_sg.id]
  }
  desired_count = 1
}


# __________________________________CONFIGURATION FOR ECS___________________________________________


# Security Group for ECS
resource "aws_security_group" "ecs_sg" {
  name        = "ecs-sg"
  description = "Security group for ECS services"
  vpc_id      = module.vpc.vpc_id

  ingress {
    from_port   = 0
    to_port     = 65535
    protocol    = "tcp"
    cidr_blocks = ["10.0.0.0/16"]
    description = "Allow all internal traffic"
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
    description = "Allow all outbound traffic"
  }

  tags = {
    Name        = "ecs_sg"
    Environment = "prod"
  }
}


# IAM Role for ECS Execution
resource "aws_iam_role" "ecs_execution_role" {
  name = "ecs_execution_role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Action = "sts:AssumeRole",
        Effect = "Allow",
        Principal = {
          Service = "ecs-tasks.amazonaws.com"
        }
      }
    ]
  })
}


resource "aws_iam_role_policy_attachment" "ecs_execution_role_attachment" {
  role       = aws_iam_role.ecs_execution_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}



resource "aws_iam_role" "ecs_task_role" {
  name = "ecs_task_role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Action = "sts:AssumeRole",
        Effect = "Allow",
        Principal = {
          Service = "ecs-tasks.amazonaws.com"
        }
      }
    ]
  })
}

resource "aws_iam_role_policy" "ecs_task_role_policy" {
  name = "ecs_task_role_policy"
  role = aws_iam_role.ecs_task_role.id

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Action = [
          "s3:GetObject",
          "s3:PutObject"
        ],
        Effect   = "Allow",
        Resource = "*"
      }
    ]
  })
}





#_______________ log ______________

resource "aws_cloudwatch_log_group" "codepipeline_log_group" {
  name              = "awslogs-codepipeline"
  retention_in_days = 14
}

resource "aws_iam_policy" "pipeline_logging_policy" {
  name        = "pipeline-logging-policy"
  description = "A policy to allow CodePipeline to write logs to CloudWatch"

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Action = [
          "logs:CreateLogStream",
          "logs:PutLogEvents"
        ],
        Effect   = "Allow",
        Resource = aws_cloudwatch_log_group.codepipeline_log_group.arn
      }
    ]
  })
}
