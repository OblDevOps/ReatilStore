variable "repository_names" {
  description = "Nombres de los repositorios ECR a crear"
  type        = list(string)
}

variable "environment" {
  description = "Ambiente de despliegue: dev, test o prod"
  type        = string
}
