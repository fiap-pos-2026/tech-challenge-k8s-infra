resource "aws_apigatewayv2_api" "http" {
  name          = "${local.name_prefix}-http-api"
  protocol_type = "HTTP"
  description   = "Gateway de entrada — auth Lambda + APIs do core"

  cors_configuration {
    allow_headers = ["Authorization", "Content-Type"]
    allow_methods = ["GET", "POST", "PUT", "PATCH", "DELETE", "OPTIONS"]
    allow_origins = ["*"]
    max_age       = 300
  }

  tags = {
    Name = "${local.name_prefix}-http-api"
  }
}

resource "aws_apigatewayv2_stage" "default" {
  api_id      = aws_apigatewayv2_api.http.id
  name        = "$default"
  auto_deploy = true

  access_log_settings {
    destination_arn = aws_cloudwatch_log_group.api_gw.arn
    format = jsonencode({
      requestId      = "$context.requestId"
      ip             = "$context.identity.sourceIp"
      requestTime    = "$context.requestTime"
      httpMethod     = "$context.httpMethod"
      routeKey       = "$context.routeKey"
      status         = "$context.status"
      protocol       = "$context.protocol"
      responseLength = "$context.responseLength"
      errorMessage   = "$context.error.message"
    })
  }

  tags = {
    Name = "${local.name_prefix}-http-api-stage"
  }

  depends_on = [aws_cloudwatch_log_group.api_gw]
}

resource "aws_cloudwatch_log_group" "api_gw" {
  name              = "/aws/apigateway/${local.name_prefix}-http-api"
  retention_in_days = 14
}

# Integração com a Lambda de auth (opcional até o auth-lambda existir)
resource "aws_apigatewayv2_integration" "auth_lambda" {
  count = var.auth_lambda_invoke_arn != "" ? 1 : 0

  api_id                 = aws_apigatewayv2_api.http.id
  integration_type       = "AWS_PROXY"
  integration_uri        = var.auth_lambda_invoke_arn
  payload_format_version = "2.0"
  integration_method     = "POST"
}

resource "aws_apigatewayv2_route" "auth" {
  count = var.auth_lambda_invoke_arn != "" ? 1 : 0

  api_id    = aws_apigatewayv2_api.http.id
  route_key = "POST /auth"
  target    = "integrations/${aws_apigatewayv2_integration.auth_lambda[0].id}"
}

# Integração HTTP com o NLB/ALB da app (preenchido após o deploy do core)
resource "aws_apigatewayv2_integration" "core" {
  count = var.core_nlb_listener_arn != "" ? 1 : 0

  api_id             = aws_apigatewayv2_api.http.id
  integration_type   = "HTTP_PROXY"
  integration_uri    = var.core_nlb_listener_arn
  integration_method = "ANY"
  connection_type    = "INTERNET"
}

resource "aws_apigatewayv2_route" "core_proxy" {
  count = var.core_nlb_listener_arn != "" ? 1 : 0

  api_id    = aws_apigatewayv2_api.http.id
  route_key = "ANY /core/{proxy+}"
  target    = "integrations/${aws_apigatewayv2_integration.core[0].id}"
}
