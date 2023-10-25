# ECS Task Definition
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
      containerPort = 3000
      hostPort      = 3000
    }]
    environment = [
      {
        name  = "PORT",
        value = "80"
      },
      {
        name  = "DB_CONNECTION_STRING",
        value = "mongodb://${var.db_username}:${var.db_password}@${aws_docdb_cluster.db_phoenix_cluster.endpoint}:${aws_docdb_cluster.db_phoenix_cluster.port}/phoenix-mongo-db"
      }
    ]
  }])
}

# ECS Cluster
resource "aws_ecs_cluster" "phoenix_cluster" {
  name = "phoenix-cluster"
}

# ECS Service
resource "aws_ecs_service" "phoenix_service" {
  name            = "phoenix-service"
  cluster         = aws_ecs_cluster.phoenix_cluster.id
  task_definition = aws_ecs_task_definition.phoenix_task.arn
  launch_type     = "FARGATE"
  network_configuration {
    subnets         = module.vpc.private_subnets
    security_groups = [aws_security_group.documentdb_sg.id]
  }
  desired_count = 1
  load_balancer {
    target_group_arn = aws_lb_target_group.my_target_group.arn
    container_name   = "phoenix-container"
    container_port   = 3000
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


resource "aws_iam_policy" "ecs_ecr_policy" {
  name        = "ecs-ecr-policy"
  description = "Policy to allow ECS tasks to authenticate to ECR"

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Action = [
          "ecr:*"

        ],
        Effect   = "Allow",
        Resource = "*"
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "ecs_execution_role_policy_attach" {
  role       = aws_iam_role.ecs_execution_role.name
  policy_arn = aws_iam_policy.ecs_ecr_policy.arn
}
