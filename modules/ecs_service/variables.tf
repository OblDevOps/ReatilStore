variable "service_name" {
  description = "Nombre del servicio"
  type        = string
}

variable "environment" {
  description = "Ambiente: dev, test o prod"
  type        = string
}

variable "vpc_id" {
  description = "ID de la VPC"
  type        = string
}

variable "public_subnet_ids" {
  description = "IDs de las subnets públicas (para el ALB)"
  type        = list(string)
}

variable "private_subnet_ids" {
  description = "IDs de las subnets privadas (para las tareas)"
  type        = list(string)
}

variable "cluster_id" {
  description = "ID del cluster ECS"
  type        = string
}

variable "container_image" {
  description = "URL de la imagen en ECR"
  type        = string
}

variable "container_port" {
  description = "Puerto donde escucha el contenedor"
  type        = number
  default     = 8080
}

variable "cpu" {
  description = "CPU para la tarea Fargate"
  type        = number
  default     = 256
}

variable "memory" {
  description = "Memoria para la tarea Fargate en MB"
  type        = number
  default     = 512
}

variable "desired_count" {
  description = "Cantidad de tareas a mantener corriendo"
  type        = number
  default     = 1
}

variable "health_check_path" {
  description = "Ruta para el health check del ALB"
  type        = string
  default     = "/"
}

variable "aws_region" {
  description = "Región de AWS"
  type        = string
  default     = "us-east-1"
}

variable "execution_role_arn" {
  description = "ARN del LabRole para ejecución de tareas ECS"
  type        = string
}

variable "min_capacity" {
  description = "Mínimo de tareas para el auto scaling"
  type        = number
  default     = 1
}

variable "max_capacity" {
  description = "Máximo de tareas para el auto scaling"
  type        = number
  default     = 3
}

variable "cpu_target" {
  description = "Porcentaje de CPU objetivo para escalar"
  type        = number
  default     = 70
}

variable "cluster_name" {
  description = "Nombre del cluster ECS"
  type        = string
}
