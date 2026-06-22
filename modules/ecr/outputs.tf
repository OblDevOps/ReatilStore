output "repository_urls" {
  description = "URLs de los repositorios ECR por servicio"
  value       = { for name, repo in aws_ecr_repository.repo : name => repo.repository_url } # arma un mapa nombre_servicio => url
}
