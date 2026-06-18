# crea un repositorio ecr por servicio
resource "aws_ecr_repository" "repo" {
  for_each = toset(var.repository_names)

  name                 = each.value
  image_tag_mutability = "MUTABLE"
  force_delete         = true # permite destroy aunque el repo tenga imágenes

  image_scanning_configuration {
    scan_on_push = true
  }

  tags = {
    Name        = each.value
    Environment = var.environment
  }
}
