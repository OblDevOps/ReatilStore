output "db_endpoint" {
  description = "DNS del NLB de Postgres"
  value       = aws_lb.db.dns_name
}
