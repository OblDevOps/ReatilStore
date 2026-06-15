variable "vpc_cidr" {
  description = "CIDR del VPC"
  type        = string
}

variable "vpc_name" {
  description = "Nombre de la vpc"
  type        = string
}

variable "environment" {
  description = "Ambiente de despliegue: dev, test o prod. Donde se ejecuta la IaC"
  type        = string
}

variable "public_subnets" {
  description = "Lista de Subnets publicas"
  type        = list(string)
}

variable "private_subnets" {
  description = "Lista de Subnets privadas"
  type        = list(string)
}

variable "availability_zones" {
  description = "Lista de Availability Zones"
  type        = list(string)
}
