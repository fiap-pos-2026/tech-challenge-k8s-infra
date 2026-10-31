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

# Integração com a Lambda de auth (opcional). Em homolog a rota /auth é criada
# pelo Terraform do auth-lambda — mantenha auth_lambda_invoke_arn vazio.
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

# --- /core via NLB interno + VPC Link ------------------------------------------

resource "aws_security_group" "api_gw_vpc_link" {
  name        = "${local.name_prefix}-apigw-vpclink-sg"
  description = "ENIs do VPC Link do API Gateway HTTP"
  vpc_id      = local.vpc_id

  tags = {
    Name = "${local.name_prefix}-apigw-vpclink-sg"
  }
}

resource "aws_vpc_security_group_egress_rule" "api_gw_vpc_link_egress" {
  security_group_id = aws_security_group.api_gw_vpc_link.id
  ip_protocol       = "-1"
  cidr_ipv4         = "0.0.0.0/0"
  description       = "Allow all egress"
}

resource "aws_apigatewayv2_vpc_link" "core" {
  name               = "${local.name_prefix}-core-vpclink"
  security_group_ids = [aws_security_group.api_gw_vpc_link.id]
  subnet_ids         = local.private_subnet_ids

  tags = {
    Name = "${local.name_prefix}-core-vpclink"
  }
}

# NLB instance mode: health check + forward usam NodePort; source = VPC (NLB/VPC Link ENIs)
resource "aws_vpc_security_group_ingress_rule" "nodes_from_vpc_nodeport" {
  security_group_id = aws_security_group.eks_nodes.id
  cidr_ipv4         = local.vpc_cidr
  ip_protocol       = "tcp"
  from_port         = 30000
  to_port           = 32767
  description       = "NLB and VPC Link to NodePort"
}

resource "aws_vpc_security_group_ingress_rule" "nodes_from_vpc_app" {
  security_group_id = aws_security_group.eks_nodes.id
  cidr_ipv4         = local.vpc_cidr
  ip_protocol       = "tcp"
  from_port         = var.core_nlb_listener_port
  to_port           = var.core_nlb_listener_port
  description       = "NLB IP-mode or direct app port from VPC"
}

# Discovery do NLB criado pelo Service LoadBalancer do core (tag do cloud-provider)
data "aws_lbs" "core" {
  tags = {
    "kubernetes.io/service-name" = var.core_k8s_service_name
  }
}

data "aws_lb_listener" "core" {
  count = var.core_nlb_listener_arn == "" && length(data.aws_lbs.core.arns) > 0 ? 1 : 0

  # aws_lbs.arns é set — precisa tolist para indexar
  load_balancer_arn = tolist(data.aws_lbs.core.arns)[0]
  port              = var.core_nlb_listener_port
}

locals {
  core_listener_arn  = var.core_nlb_listener_arn != "" ? var.core_nlb_listener_arn : try(data.aws_lb_listener.core[0].arn, "")
  core_route_enabled = local.core_listener_arn != ""
}

resource "aws_apigatewayv2_integration" "core" {
  count = local.core_route_enabled ? 1 : 0

  api_id             = aws_apigatewayv2_api.http.id
  integration_type   = "HTTP_PROXY"
  integration_uri    = local.core_listener_arn
  integration_method = "ANY"
  connection_type    = "VPC_LINK"
  connection_id      = aws_apigatewayv2_vpc_link.core.id
}

locals {
  core_routes = toset([
    "ANY /core",
    "ANY /core/{proxy+}",
  ])
}

resource "aws_apigatewayv2_route" "core" {
  for_each = local.core_route_enabled ? local.core_routes : toset([])

  api_id    = aws_apigatewayv2_api.http.id
  route_key = each.value
  target    = "integrations/${aws_apigatewayv2_integration.core[0].id}"
}
