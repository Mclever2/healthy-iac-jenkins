resource "aws_apigatewayv2_api" "http_api" {
  name          = "healthy-api-gateway-ec2-${terraform.workspace}"
  protocol_type = "HTTP"
}

resource "aws_apigatewayv2_integration" "ec2_integration" {
  api_id           = aws_apigatewayv2_api.http_api.id
  integration_type = "HTTP_PROXY"  # Para redirigir tráfico directamente a la EC2
  integration_uri  = "http://${aws_instance.backend.private_ip}:8080/{proxy}"  # Usa private_ip (recomendado) o public_ip
  integration_method = "ANY"
  payload_format_version = "1.0"
}

resource "aws_apigatewayv2_route" "proxy_route" {
  api_id    = aws_apigatewayv2_api.http_api.id
  route_key = "ANY /{proxy+}"
  target    = "integrations/${aws_apigatewayv2_integration.ec2_integration.id}"
}

resource "aws_apigatewayv2_stage" "default" {
  api_id      = aws_apigatewayv2_api.http_api.id
  name        = "$default"
  auto_deploy = true
}