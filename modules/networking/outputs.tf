output "vpc_id" {
  description = "ID de la VPC, usado por otros módulos (ECS, RDS) para desplegar dentro de la red"
  value       = aws_vpc.main.id
}

output "public_subnet_ids" {
  description = "IDs de las subnets públicas, donde se ubica el ALB"
  value       = aws_subnet.public_subnet[*].id
}

output "private_subnet_ids" {
  description = "IDs de las subnets privadas, donde corren los microservicios y la base de datos"
  value       = aws_subnet.private_subnet[*].id
}
