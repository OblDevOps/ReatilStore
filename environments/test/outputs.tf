output "vpc_id" {
  description = "ID de la VPC del ambiente dev"
  value       = module.network.vpc_id
}

output "public_subnet_ids" {
  description = "IDs de las subnets públicas"
  value       = module.network.public_subnet_ids
}

output "private_subnet_ids" {
  description = "IDs de las subnets privadas"
  value       = module.network.private_subnet_ids
}

#ruta de la ui
output "ui_alb_dns" {
  description = "URL pública del servicio ui"
  value       = module.service_ui.alb_dns_name
}

#ruta de la ui-admin
output "ui_admin_alb_dns" {
  description = "URL pública del servicio admin"
  value       = module.service_admin.alb_dns_name
}

output "api_gateway_ui_url" {
  description = "URL pública de API Gateway delante de la UI con throttling"
  value       = module.api_gateway.invoke_url
}
