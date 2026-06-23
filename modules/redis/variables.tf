variable "environment" {
  description = "Ambiente: dev, test o prod"
  type        = string
}
variable "vpc_id" {
  description = "ID de la VPC"
  type        = string
}
variable "vpc_cidr" {
  description = "CIDR de la VPC, para restringir el security group al tráfico interno"
  type        = string
}
variable "private_subnet_ids" {
  description = "IDs de las subnets privadas donde corren las tareas y el NLB"
  type        = list(string)
}
variable "cluster_id" {
  description = "ID del cluster ECS"
  type        = string
}
variable "execution_role_arn" {
  description = "ARN del rol de ejecución (LabRole)"
  type        = string
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
variable "aws_region" {
  description = "Región de AWS para los logs de CloudWatch"
  type        = string
  default     = "us-east-1"
}
