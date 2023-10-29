resource "aws_ecs_task_definition" "mongodb_backup_task" {
  family                   = "mongodb-backup-task"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = "512"
  memory                   = "1024"
  execution_role_arn       = aws_iam_role.ecs_execution_role.arn

  container_definitions = jsonencode([{
    name  = "mongodb-backup-container"
    image = "mongo:4.4"

    entryPoint = ["/bin/sh", "-c"]
    command    = ["mongodump --uri=$DB_CONNECTION_STRING && aws s3 cp /dump s3://phoenix-mongodb-backup-bucket/"]

    logConfiguration = {
      logDriver = "awslogs"
      options = {
        awslogs-group         = aws_cloudwatch_log_group.mongodb_backup_log_group.name
        awslogs-region        = var.aws_region
        awslogs-stream-prefix = "mongodb-backup"
      }
    }

    environment = [
      {
        name  = "DB_CONNECTION_STRING",
        value = "mongodb://${var.db_username}:${var.db_password}@mongodb-service:27017/phoenix-mongo-db"
      }
    ]
  }])
}

resource "aws_cloudwatch_event_rule" "every_day" {
  schedule_expression = "rate(1 day)"
}

resource "aws_cloudwatch_event_target" "run_mongodb_backup_task" {
  rule      = aws_cloudwatch_event_rule.every_day.name
  arn       = aws_ecs_cluster.phoenix_cluster.arn
  role_arn  = aws_iam_role.ecs_events_role.arn

  ecs_target {
    task_count          = 1
    task_definition_arn = aws_ecs_task_definition.mongodb_backup_task.arn
    launch_type         = "FARGATE"
    network_configuration {
      subnets = module.vpc.private_subnets
    }
  }
}


resource "aws_iam_role" "ecs_events_role" {
  name = "ecs_events_role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Action = "sts:AssumeRole",
        Effect = "Allow",
        Principal = {
          Service = "events.amazonaws.com"
        }
      }
    ]
  })
}

resource "aws_cloudwatch_log_group" "mongodb_backup_log_group" {
  name              = "mongodb-backup-logs"
  retention_in_days = 7
}
