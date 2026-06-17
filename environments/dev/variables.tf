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
