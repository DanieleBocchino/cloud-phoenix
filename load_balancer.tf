# Load Balancer phoenix
resource "aws_lb" "phoenix_alb" {
  name               = "phoenix-alb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.ecs_sg.id]
  subnets            = module.vpc.public_subnets

  enable_deletion_protection = false
}

resource "aws_lb_target_group" "phoenix_target_group" {
  name        = "phoenix-target-group"
  port        = var.port
  protocol    = "HTTP"
  vpc_id      = module.vpc.vpc_id
  target_type = "ip"
}

resource "aws_lb_listener" "phoenix_listener" {
  load_balancer_arn = aws_lb.phoenix_alb.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.phoenix_target_group.arn
  }
}