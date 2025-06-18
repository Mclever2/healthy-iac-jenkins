resource "aws_apigatewayv2_vpc_link" "alb_link" {
  name        = "healthy-vpc-link"
  subnet_ids  = [aws_subnet.main_subnet_1.id, aws_subnet.main_subnet_2.id]
  security_group_ids = [aws_security_group.alb_sg.id]
}

resource "aws_apigatewayv2_api" "http_proxy_api" {
  name          = "healthy-api-gateway"
  protocol_type = "HTTP"
}

resource "aws_apigatewayv2_integration" "alb_integration" {
  api_id           = aws_apigatewayv2_api.http_proxy_api.id
  integration_type = "HTTP_PROXY"
  integration_uri  = aws_lb_listener.front_end.arn
  integration_method = "ANY"
  connection_type  = "VPC_LINK"
  connection_id    = aws_apigatewayv2_vpc_link.alb_link.id
  payload_format_version = "1.0"
}

resource "aws_apigatewayv2_route" "root_route" {
  api_id    = aws_apigatewayv2_api.http_proxy_api.id
  route_key = "ANY /{proxy+}"
  target    = "integrations/${aws_apigatewayv2_integration.alb_integration.id}"
}

resource "aws_apigatewayv2_stage" "default" {
  api_id      = aws_apigatewayv2_api.http_proxy_api.id
  name        = "$default"
  auto_deploy = true
}