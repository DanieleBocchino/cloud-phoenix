# __________________________________________________ ECS __________________________________________________
resource "aws_ecs_cluster" "ecs_phoenix_cluster" {
  name = "phoenix-cluster"
}

resource "aws_ecs_task_definition" "phoenix_task" {
  family                   = "phoenix"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = "256"
  memory                   = "512"
  execution_role_arn       = aws_iam_role.ecs_execution_role.arn

  container_definitions = jsonencode([{
    name  = "phoenix",
    image = "${aws_ecr_repository.phoenix_repository.repository_url}:latest",
    portMappings = [{
      containerPort = 80,
      hostPort      = 80
    }],
  }])
}

resource "aws_ecs_service" "phoenix_service" {
  name            = "phoenix-service"
  cluster         = aws_ecs_cluster.ecs_phoenix_cluster.id
  task_definition = aws_ecs_task_definition.phoenix_task.arn
  launch_type     = "FARGATE"
  desired_count   = 1

  network_configuration {
    subnets         = module.vpc.private_subnets
    security_groups = [module.phoenix_sg.security_group_id]
  }

 
}
