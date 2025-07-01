resource "aws_cloudfront_origin_access_control" "s3_oac" {
  name                              = "oac-s3-${terraform.workspace}"
  description                       = "Access control para CloudFront con S3"
  origin_access_control_origin_type = "s3"
  signing_behavior                  = "always"
  signing_protocol                  = "sigv4"
}

resource "aws_cloudfront_distribution" "s3_distribution" {
  enabled             = true
  default_root_object = "index.html"

  # Origen S3
  origin {
    domain_name = "${var.bucket_name}.s3.amazonaws.com"
    origin_id   = "s3-origin"
    origin_access_control_id = aws_cloudfront_origin_access_control.s3_oac.id
  }

  # Origen API Gateway
  origin {
    domain_name = "l4tnjoxj80.execute-api.us-east-1.amazonaws.com"
    origin_id   = "api-gateway-origin"

    custom_origin_config {
      http_port              = 80
      https_port             = 443
      origin_protocol_policy = "https-only"
      origin_ssl_protocols   = ["TLSv1.2"]
    }
  }

  # Comportamiento por defecto (S3)
  default_cache_behavior {
    target_origin_id       = "s3-origin"
    viewer_protocol_policy = "redirect-to-https"
    allowed_methods        = ["GET", "HEAD"]
    cached_methods         = ["GET", "HEAD"]

    forwarded_values {
      query_string = false
      cookies {
        forward = "none"
      }
    }
  }

  # Ruta para /api/* (redirige al API Gateway)
  ordered_cache_behavior {
    path_pattern     = "/api/*"
    target_origin_id = "api-gateway-origin"

    viewer_protocol_policy = "redirect-to-https"
    allowed_methods        = ["GET", "HEAD", "OPTIONS", "PUT", "POST", "DELETE", "PATCH"]
    cached_methods         = ["GET", "HEAD"]

    forwarded_values {
      query_string = true
      headers      = ["Authorization"]
      cookies {
        forward = "all"
      }
    }

    compress = true
  }

  viewer_certificate {
    cloudfront_default_certificate = true
  }

  restrictions {
    geo_restriction {
      restriction_type = "none"
    }
  }

  # Asociar WAF
  web_acl_id = aws_wafv2_web_acl.cloudfront_waf.arn

  tags = {
    Name = "CloudFront-to-S3-and-API"
  }

  depends_on = [aws_cloudfront_origin_access_control.s3_oac]
}
