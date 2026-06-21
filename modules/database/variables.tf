variable "environment" {
  description = "Ambiente: dev, test o prod"
  type        = string
}

variable "vpc_id" {
  description = "ID de la VPC"
  type        = string
}

variable "vpc_cidr" {
  description = "CIDR de la VPC"
  type        = string
}

variable "private_subnet_ids" {
  description = "IDs de las subnets privadas"
  type        = list(string)
}

variable "cluster_id" {
  description = "ID del cluster ECS"
  type        = string
}

variable "container_image" {
  description = "URL de la imagen de Postgres en ECR"
  type        = string
}

variable "execution_role_arn" {
  description = "ARN del rol de ejecución (LabRole)"
  type        = string
}

variable "db_user" {
  description = "Usuario de Postgres"
  type        = string
  default     = "retail_user"
}

variable "db_secret_arn" {
  description = "ARN del secret en Secrets Manager con el password de Postgres"
  type        = string
}

variable "db_name" {
  description = "Base de datos inicial"
  type        = string
  default     = "orders"
}

variable "cpu" {
  description = "CPU para la tarea"
  type        = number
  default     = 256
}

variable "memory" {
  description = "Memoria en MB"
  type        = number
  default     = 512
}

variable "aws_region" {
  description = "Región de AWS"
  type        = string
  default     = "us-east-1"
}
