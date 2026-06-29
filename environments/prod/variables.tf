variable "vpc_cidr" {
  description = "CIDR de la VPC"
  type        = string
}

variable "vpc_name" {
  description = "Nombre base de la VPC y sus recursos"
  type        = string
}

variable "environment" {
  description = "Ambiente de despliegue: dev, test o prod"
  type        = string
}

variable "public_subnets" {
  description = "Lista de CIDRs para las subnets públicas, una por AZ"
  type        = list(string)
}

variable "private_subnets" {
  description = "Lista de CIDRs para las subnets privadas, una por AZ"
  type        = list(string)
}

variable "availability_zones" {
  description = "Lista de AZs, en el mismo orden que las subnets"
  type        = list(string)
}

variable "repository_names" {
  description = "Microservicios que tendrán repositorio ECR"
  type        = list(string)
}

variable "cluster_name" {
  description = "Nombre del cluster ECS"
  type        = string
}

variable "db_password" {
  description = "Password de la base de datos"
  type        = string
  sensitive   = true
}

variable "admin_password" {
  description = "Password del admin"
  type        = string
  sensitive   = true
}

variable "admin_jwt_secret" {
  description = "JWT secret del admin"
  type        = string
  sensitive   = true
}

variable "admin_username" {
  description = "Nombre de usuario del administrador"
  type        = string
  default     = "admin"
}

variable "single_nat_gateway" {
  description = "Si es true, usa un único NAT Gateway compartido por todas las subnets privadas"
  type        = bool
  default     = false
}
