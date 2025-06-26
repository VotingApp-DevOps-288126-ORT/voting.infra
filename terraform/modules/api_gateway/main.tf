resource "aws_apigatewayv2_api" "voting_api" {
  name          = var.name
  protocol_type = "HTTP"
}

# Integration

resource "aws_apigatewayv2_integration" "dev" {
  api_id                 = aws_apigatewayv2_api.voting_api.id
  integration_type       = "HTTP_PROXY"
  connection_type        = "INTERNET"
  integration_method     = "ANY"
  integration_uri        = "http://${var.dev_ingress_dns}"
  payload_format_version = "1.0"

  request_parameters = {
    "overwrite:path" = "/$request.path.proxy"
  }
}

resource "aws_apigatewayv2_integration" "test" {
  api_id                 = aws_apigatewayv2_api.voting_api.id
  integration_type       = "HTTP_PROXY"
  connection_type        = "INTERNET"
  integration_method     = "ANY"
  integration_uri        = "http://${var.test_ingress_dns}"
  payload_format_version = "1.0"

  request_parameters = {
    "overwrite:path" = "/$request.path.proxy"
  }
}

resource "aws_apigatewayv2_integration" "prod" {
  api_id                 = aws_apigatewayv2_api.voting_api.id
  integration_type       = "HTTP_PROXY"
  connection_type        = "INTERNET"
  integration_method     = "ANY"
  integration_uri        = "http://${var.prod_ingress_dns}"
  payload_format_version = "1.0"

  request_parameters = {
    "overwrite:path" = "/$request.path.proxy"
  }
}

# Mapear Routes

resource "aws_apigatewayv2_route" "dev" {
  api_id    = aws_apigatewayv2_api.voting_api.id
  route_key = "ANY /dev/{proxy+}"
  target    = "integrations/${aws_apigatewayv2_integration.dev.id}"
}

resource "aws_apigatewayv2_route" "test" {
  api_id    = aws_apigatewayv2_api.voting_api.id
  route_key = "ANY /test/{proxy+}"
  target    = "integrations/${aws_apigatewayv2_integration.test.id}"
}

resource "aws_apigatewayv2_route" "prod" {
  api_id    = aws_apigatewayv2_api.voting_api.id
  route_key = "ANY /prod/{proxy+}"
  target    = "integrations/${aws_apigatewayv2_integration.prod.id}"
}

resource "aws_apigatewayv2_stage" "default" {
  api_id      = aws_apigatewayv2_api.voting_api.id
  name        = "$default"
  auto_deploy = true
}
