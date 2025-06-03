## variables.tf

# --- General ---
variable "region" {
  description = "AWS region"
  type        = string
  default     = "us-east-1"
}

# --- S3 Bucket ---
variable "bucket_name" {
  description = "Nombre del bucket S3"
  type        = string
  default     = "healthy-app-files-1234567890"
}

# --- Cognito ---
variable "cognito_user_pool_name" {
  description = "Nombre del User Pool de Cognito"
  type        = string
  default     = "healthy-user-pool"
}

variable "cognito_user_pool_client_name" {
  description = "Nombre del Cliente de Cognito"
  type        = string
  default     = "healthy-client"
}

# --- IAM ---

# --- VPC y Networking ---
variable "vpc_cidr" {
  description = "CIDR block para la VPC"
  type        = string
  default     = "10.0.0.0/16"
}

variable "subnet_cidr_1" {
  description = "CIDR block para la subred 1"
  type        = string
  default     = "10.0.1.0/24"
}

variable "subnet_cidr_2" {
  description = "CIDR block para la subred 2"
  type        = string
  default     = "10.0.2.0/24"
}

variable "availability_zone_1" {
  description = "Zona de disponibilidad 1"
  type        = string
  default     = "us-east-1a"
}

variable "availability_zone_2" {
  description = "Zona de disponibilidad 2"
  type        = string
  default     = "us-east-1b"
}

# --- Base de Datos RDS ---
variable "db_name" {
  description = "Nombre de la base de datos PostgreSQL"
  type        = string
  default     = "healthy_db"
}

variable "db_username" {
  description = "Usuario administrador para la base de datos"
  type        = string
  default     = "healthyadmin"
}

variable "db_password" {
  description = "Contraseña del usuario administrador de la base de datos"
  type        = string
  sensitive   = true
  default     = "PasswordSegura123"
}

variable "db_instance_class" {
  description = "Tipo de instancia para la base de datos RDS"
  type        = string
  default     = "db.t3.micro"
}

variable "db_allocated_storage" {
  description = "Cantidad de almacenamiento (GB) para la base de datos"
  type        = number
  default     = 20
}

# --- EC2 ---
variable "ec2_instance_type" {
  description = "Tipo de instancia EC2"
  type        = string
  default     = "t3.micro"
}

variable "key_pair_name" {
  description = "Nombre de la key pair existente en AWS para conectarse a la instancia EC2"
  type        = string
  default     = "healthy-key"
}

variable "ec2_ami" {
  description = "AMI para la instancia EC2 (Amazon Linux 2)"
  type        = string
  default     = "ami-0c2b8ca1dad447f8a" # Amazon Linux 2 en us-east-1
}

# --- Seguridad y acceso ---
variable "my_ip" {
  description = "Tu IP pública para acceso SSH u otros (formato CIDR)"
  type        = string
  default     = "0.0.0.0/0"  # Por defecto abierto, CAMBIAR para seguridad
}


