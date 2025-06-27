resource "aws_apigatewayv2_api" "voting_api" {
  name          = var.name
  protocol_type = "HTTP"
}

# Integration

resource "aws_apigatewayv2_integration" "vote" {
  api_id                 = aws_apigatewayv2_api.voting_api.id
  integration_type       = "HTTP_PROXY"
  connection_type        = "INTERNET"
  integration_method     = "ANY"
  integration_uri        = "http://${var.ingress_dns_vote}"
  payload_format_version = "1.0"

  request_parameters = {
    "overwrite:path" = "/$request.path.proxy"
  }
}

resource "aws_apigatewayv2_integration" "result" {
  api_id                 = aws_apigatewayv2_api.voting_api.id
  integration_type       = "HTTP_PROXY"
  connection_type        = "INTERNET"
  integration_method     = "ANY"
  integration_uri        = "http://${var.ingress_dns_result}"
  payload_format_version = "1.0"

  request_parameters = {
    "overwrite:path" = "/$request.path.proxy"
  }
}

# Mapear Routes

resource "aws_apigatewayv2_route" "dev" {
  api_id    = aws_apigatewayv2_api.voting_api.id
  route_key = "ANY /vote/{proxy+}"
  target    = "integrations/${aws_apigatewayv2_integration.vote.id}"
}

resource "aws_apigatewayv2_route" "test" {
  api_id    = aws_apigatewayv2_api.voting_api.id
  route_key = "ANY /result/{proxy+}"
  target    = "integrations/${aws_apigatewayv2_integration.result.id}"
}

resource "aws_apigatewayv2_stage" "default" {
  api_id      = aws_apigatewayv2_api.voting_api.id
  name        = "$default"
  auto_deploy = true
}
