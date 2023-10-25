# _________________________ SNS Topics _________________________

resource "aws_sns_topic" "cpu_alerts" {
  name = "cpu_alerts"
}

resource "aws_sns_topic" "service_status" {
  name = "service-status"
}

# SNS Subscriptions

resource "aws_sns_topic_subscription" "cpu_alerts_email" {
  topic_arn = aws_sns_topic.cpu_alerts.arn
  protocol  = "email"
  endpoint  = var.alert_email
}

resource "aws_sns_topic_subscription" "lambda_subscription" {
  topic_arn = aws_sns_topic.service_status.arn
  protocol  = "lambda"
  endpoint  = aws_lambda_function.ecs_restart_lambda.arn
}

# __________________ CloudWatch Log Group _________________________

resource "aws_cloudwatch_log_group" "phoenix_log_group" {
  name              = "/ecs/phoenix"
  retention_in_days = 7
}

# CloudWatch Alarms

resource "aws_cloudwatch_metric_alarm" "cpu_utilization_high" {
  alarm_name          = "cpu-utilization-high"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = "1"
  metric_name         = "CPUUtilization"
  namespace           = "AWS/ECS"
  period              = "60"
  statistic           = "Average"
  threshold           = "80"
  alarm_description   = "This metric triggers when CPU utilization is 80% or higher"
  alarm_actions       = [aws_sns_topic.cpu_alerts.arn]

  dimensions = {
    ClusterName = aws_ecs_cluster.phoenix_cluster.name
    ServiceName = aws_ecs_service.phoenix_service.name
  }
}

resource "aws_cloudwatch_metric_alarm" "ecs_service_alarm" {
  alarm_name          = "ecs-service-down"
  comparison_operator = "LessThanThreshold"
  evaluation_periods  = "1"
  metric_name         = "CPUUtilization"
  namespace           = "AWS/ECS"
  period              = "60"
  statistic           = "SampleCount"
  threshold           = "1"
  alarm_description   = "This metric triggers when the ECS service is down."
  alarm_actions       = [aws_sns_topic.service_status.arn]

  dimensions = {
    ClusterName = aws_ecs_cluster.phoenix_cluster.name
    ServiceName = aws_ecs_service.phoenix_service.name
  }
}