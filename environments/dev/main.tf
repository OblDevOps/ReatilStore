data "aws_iam_role" "labrole" {
  name = "LabRole"
}

module "network" {
  source             = "../../modules/networking"
  vpc_cidr           = var.vpc_cidr
  vpc_name           = var.vpc_name
  environment        = var.environment
  public_subnets     = var.public_subnets
  private_subnets    = var.private_subnets
  availability_zones = var.availability_zones
}

module "ecr" {
  source           = "../../modules/ecr"
  repository_names = var.repository_names
  environment      = var.environment
}

module "ecs" {
  source       = "../../modules/ecs"
  cluster_name = var.cluster_name
  environment  = var.environment
}

# modulo para el servicio de ui.
module "service_ui" {
  source = "../../modules/ecs_service"

  service_name = "ui"
  environment  = var.environment

  # de la red
  vpc_id             = module.network.vpc_id
  public_subnet_ids  = module.network.public_subnet_ids
  private_subnet_ids = module.network.private_subnet_ids

  #  cluster
  cluster_id   = module.ecs.cluster_id
  cluster_name = module.ecs.cluster_name


  container_image = "${module.ecr.repository_urls["ui"]}:latest"

  # configuración del contenedor
  container_port    = 8080
  cpu               = 256
  memory            = 512
  desired_count     = 1
  health_check_path = "/health"

  # precisamos el rol de ejecución (LabRole en el Learner Lab)
  execution_role_arn = data.aws_iam_role.labrole.arn
}
