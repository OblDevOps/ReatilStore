variable "vpc_cidr" {
  description = "CIDR del VPC"
  type        = string
}

variable "project" {
  description = "Nombre del proyecto, usado para nombrar recursos"
  type        = string
}

variable "environment" {
  description = "Ambiente de despliegue: dev, test o prod"
  type        = string
}
