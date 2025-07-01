# Configuración de CloudWatch Logs
resource "aws_cloudwatch_log_group" "app_log_group" {
  name              = "/ecs/healthy-iac-app-${terraform.workspace}"
  retention_in_days = 30
  tags = {
    Environment = "production"
    Application = "healthy-iac"
  }
}

# IAM Role para Grafana
resource "aws_iam_role" "grafana_cloudwatch_role" {
  name = "grafana-cloudwatch-role-${terraform.workspace}"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "grafana.amazonaws.com"
        }
      }
    ]
  })
}

# Política para acceder a CloudWatch
resource "aws_iam_policy" "grafana_cloudwatch_policy" {
  name        = "grafana-cloudwatch-policy-${terraform.workspace}"
  description = "Permite a Grafana leer métricas de CloudWatch"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = [
          "cloudwatch:DescribeAlarmsForMetric",
          "cloudwatch:DescribeAlarms",
          "cloudwatch:ListMetrics",
          "cloudwatch:GetMetricStatistics",
          "cloudwatch:GetMetricData",
          "logs:DescribeLogGroups",
          "logs:GetLogGroupFields",
          "logs:StartQuery",
          "logs:StopQuery",
          "logs:GetQueryResults",
          "logs:GetLogEvents"
        ],
        Effect   = "Allow",
        Resource = "*"
      }
    ]
  })
}

# Adjuntar política al rol
resource "aws_iam_role_policy_attachment" "grafana_cloudwatch" {
  role       = aws_iam_role.grafana_cloudwatch_role.name
  policy_arn = aws_iam_policy.grafana_cloudwatch_policy.arn
}

# Exportar outputs
output "grafana_role_arn" {
  value = aws_iam_role.grafana_cloudwatch_role.arn
}