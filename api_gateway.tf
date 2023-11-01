resource "aws_api_gateway_rest_api" "phoenix_api" {
  name        = "phoenix-api"
  description = "API for Phoenix Application"
  endpoint_configuration {
    types = ["REGIONAL"]
  }
}

resource "aws_api_gateway_resource" "generatecert_resource" {
  rest_api_id = aws_api_gateway_rest_api.phoenix_api.id
  parent_id   = aws_api_gateway_rest_api.phoenix_api.root_resource_id
  path_part   = "generatecert"
}

resource "aws_api_gateway_method" "generatecert_method" {
  rest_api_id   = aws_api_gateway_rest_api.phoenix_api.id
  resource_id   = aws_api_gateway_resource.generatecert_resource.id
  http_method   = "GET"
  authorization = "NONE"
}

resource "aws_api_gateway_method_settings" "generatecert_throttling" {
  rest_api_id = aws_api_gateway_rest_api.phoenix_api.id
  stage_name  = "production"
  method_path = "${aws_api_gateway_resource.generatecert_resource.path_part}/GET"

  settings {
    throttling_burst_limit = 20
    throttling_rate_limit  = 10
  }
}

resource "aws_api_gateway_integration" "generatecert_integration" {
  rest_api_id = aws_api_gateway_rest_api.phoenix_api.id
  resource_id = aws_api_gateway_resource.generatecert_resource.id
  http_method = aws_api_gateway_method.generatecert_method.http_method

  type                    = "HTTP_PROXY"
  integration_http_method = "GET"
  uri                     = "http://${aws_lb.phoenix_alb.dns_name}/generatecert"
}

resource "aws_api_gateway_deployment" "phoenix_api_deployment" {
  rest_api_id = aws_api_gateway_rest_api.phoenix_api.id
  stage_name  = "production"
}

