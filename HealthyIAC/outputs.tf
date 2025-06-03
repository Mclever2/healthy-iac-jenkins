# S3 Bucket
output "s3_bucket_name" {
  description = "Nombre del bucket S3 creado"
  value       = aws_s3_bucket.healthy_app_files.bucket
}

# Cognito User Pool
output "cognito_user_pool_id" {
  description = "ID del User Pool de Cognito"
  value       = aws_cognito_user_pool.healthy_user_pool.id
}

output "cognito_user_pool_client_id" {
  description = "ID del Cliente del User Pool de Cognito"
  value       = aws_cognito_user_pool_client.healthy_user_pool_client.id
}

# RDS Outputs
output "rds_endpoint" {
  description = "Endpoint de conexión de la base de datos"
  value       = aws_db_instance.healthy.endpoint
}

output "rds_name" {
  description = "Nombre de la base de datos"
  value       = aws_db_instance.healthy.db_name
}

output "rds_username" {
  description = "Usuario administrador de la base de datos"
  value       = aws_db_instance.healthy.username
}

# EC2 Outputs
output "ec2_public_ip" {
  description = "La IP pública de la instancia EC2"
  value       = aws_instance.backend.public_ip
}

output "ec2_private_ip" {
  description = "La IP privada de la instancia EC2"
  value       = aws_instance.backend.private_ip
}
