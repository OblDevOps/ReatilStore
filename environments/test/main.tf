data "aws_iam_role" "labrole" {
  name = "LabRole"
}

module "network" {
  source              = "../../modules/networking"
  vpc_cidr            = var.vpc_cidr
  vpc_name            = var.vpc_name
  environment         = var.environment
  public_subnets      = var.public_subnets
  private_subnets     = var.private_subnets
  availability_zones  = var.availability_zones
  single_nat_gateway  = var.single_nat_gateway
}

# Los repos ECR son compartidos entre ambientes (creados y gestionados por dev)
data "aws_ecr_repository" "repos" {
  for_each = toset(var.repository_names)
  name     = each.value
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


  container_image = "${data.aws_ecr_repository.repos["ui"].repository_url}:latest"

  # configuración del contenedor
  container_port    = 8080
  cpu               = 256
  memory            = 512
  desired_count     = 1
  health_check_path = "/health"

  environment_variables = [
    { name = "RETAIL_UI_ENDPOINTS_CATALOG", value = "http://${module.service_catalog.alb_dns_name}" },
    { name = "RETAIL_UI_ENDPOINTS_CHECKOUT", value = "http://${module.service_checkout.alb_dns_name}" },
    { name = "RETAIL_UI_ENDPOINTS_CARTS", value = "http://${module.service_cart.alb_dns_name}" },
    { name = "RETAIL_UI_ENDPOINTS_ORDERS", value = "http://${module.service_orders.alb_dns_name}" },
  ]
  # precisamos el rol de ejecución (LabRole en el Learner Lab)
  execution_role_arn = data.aws_iam_role.labrole.arn
}

# API Gateway delante del servicio UI con throttling nativo
module "api_gateway_ui" {
  source = "../../modules/apigateway"

  service_name     = "${var.environment}-retailstore"
  backend_dns_name = module.service_ui.alb_dns_name
}

# Base de datos PostgreSQL compartida (atras de nlb interno)
module "database" {
  source = "../../modules/database"

  environment        = var.environment
  vpc_id             = module.network.vpc_id
  vpc_cidr           = var.vpc_cidr
  private_subnet_ids = module.network.private_subnet_ids
  cluster_id         = module.ecs.cluster_id

  container_image    = "${data.aws_ecr_repository.repos["db"].repository_url}:latest"
  execution_role_arn = data.aws_iam_role.labrole.arn

  db_secret_arn = aws_secretsmanager_secret.db_password.arn
}

# Servicio interno. catalog (ALB interno conectado a Postgres)
module "service_catalog" {
  source = "../../modules/ecs_service"

  service_name = "catalog"
  environment  = var.environment
  internal     = true

  vpc_id             = module.network.vpc_id
  vpc_cidr           = var.vpc_cidr
  public_subnet_ids  = module.network.public_subnet_ids
  private_subnet_ids = module.network.private_subnet_ids

  cluster_id   = module.ecs.cluster_id
  cluster_name = module.ecs.cluster_name

  container_image = "${data.aws_ecr_repository.repos["catalog"].repository_url}:latest"

  container_port    = 8080
  cpu               = 256
  memory            = 512
  desired_count     = 1
  health_check_path = "/health"

  # Conexión a la base de datos (vía el NLB)
  environment_variables = [
    { name = "GIN_MODE", value = "release" },
    { name = "RETAIL_CATALOG_PERSISTENCE_PROVIDER", value = "postgres" },
    { name = "RETAIL_CATALOG_PERSISTENCE_ENDPOINT", value = "${module.database.db_endpoint}:5432" },
    { name = "RETAIL_CATALOG_PERSISTENCE_DB_NAME", value = "catalogdb" },
    { name = "RETAIL_CATALOG_PERSISTENCE_USER", value = "retail_user" },
  ]

  secret_arns = [
    {
      name      = "RETAIL_CATALOG_PERSISTENCE_PASSWORD"
      valueFrom = aws_secretsmanager_secret.db_password.arn
    }
  ]

  execution_role_arn = data.aws_iam_role.labrole.arn
}

module "service_orders" {
  source = "../../modules/ecs_service"

  service_name = "orders"
  environment  = var.environment
  internal     = true

  vpc_id             = module.network.vpc_id
  vpc_cidr           = var.vpc_cidr
  public_subnet_ids  = module.network.public_subnet_ids
  private_subnet_ids = module.network.private_subnet_ids

  cluster_id   = module.ecs.cluster_id
  cluster_name = module.ecs.cluster_name

  container_image   = "${data.aws_ecr_repository.repos["orders"].repository_url}:latest"
  container_port    = 8080
  cpu               = 256
  memory            = 512
  desired_count     = 1
  health_check_path = "/health"

  environment_variables = [
    { name = "RETAIL_ORDERS_PERSISTENCE_ENDPOINT", value = "${module.database.db_endpoint}:5432" },
    { name = "RETAIL_ORDERS_PERSISTENCE_NAME", value = "orders" },
    { name = "RETAIL_ORDERS_PERSISTENCE_USERNAME", value = "retail_user" },
  ]

  secret_arns = [
    {
      name      = "RETAIL_ORDERS_PERSISTENCE_PASSWORD"
      valueFrom = aws_secretsmanager_secret.db_password.arn
    }
  ]

  execution_role_arn = data.aws_iam_role.labrole.arn
}

module "service_cart" {
  source = "../../modules/ecs_service"

  service_name = "cart"
  environment  = var.environment
  internal     = true

  vpc_id             = module.network.vpc_id
  vpc_cidr           = var.vpc_cidr
  public_subnet_ids  = module.network.public_subnet_ids
  private_subnet_ids = module.network.private_subnet_ids

  cluster_id   = module.ecs.cluster_id
  cluster_name = module.ecs.cluster_name

  container_image   = "${data.aws_ecr_repository.repos["cart"].repository_url}:latest"
  container_port    = 8080
  cpu               = 256
  memory            = 512
  desired_count     = 1
  health_check_path = "/health"

  environment_variables = [
    { name = "CART_PERSISTENCE_PROVIDER", value = "postgres" },
    { name = "CART_POSTGRES_HOST", value = module.database.db_endpoint },
    { name = "CART_POSTGRES_PORT", value = "5432" },
    { name = "CART_POSTGRES_DB", value = "cartdb" },
    { name = "CART_POSTGRES_USER", value = "retail_user" },
  ]

  secret_arns = [
    {
      name      = "CART_POSTGRES_PASSWORD"
      valueFrom = aws_secretsmanager_secret.db_password.arn
    }
  ]

  execution_role_arn = data.aws_iam_role.labrole.arn
}

module "redis" {
  source = "../../modules/redis"

  environment        = var.environment
  vpc_id             = module.network.vpc_id
  vpc_cidr           = var.vpc_cidr
  private_subnet_ids = module.network.private_subnet_ids
  cluster_id         = module.ecs.cluster_id
  execution_role_arn = data.aws_iam_role.labrole.arn
}


module "service_checkout" {
  source = "../../modules/ecs_service"

  service_name = "checkout"
  environment  = var.environment
  internal     = true

  vpc_id             = module.network.vpc_id
  vpc_cidr           = var.vpc_cidr
  public_subnet_ids  = module.network.public_subnet_ids
  private_subnet_ids = module.network.private_subnet_ids

  cluster_id   = module.ecs.cluster_id
  cluster_name = module.ecs.cluster_name

  container_image   = "${data.aws_ecr_repository.repos["checkout"].repository_url}:latest"
  container_port    = 8080
  cpu               = 256
  memory            = 512
  desired_count     = 1
  health_check_path = "/health"

  environment_variables = [
    { name = "RETAIL_CHECKOUT_PERSISTENCE_PROVIDER", value = "redis" },
    { name = "RETAIL_CHECKOUT_PERSISTENCE_REDIS_URL", value = "redis://${module.redis.redis_endpoint}:6379" },
    { name = "RETAIL_CHECKOUT_ENDPOINTS_ORDERS", value = "http://${module.service_orders.alb_dns_name}" },
  ]

  execution_role_arn = data.aws_iam_role.labrole.arn
}

module "service_admin" {
  source = "../../modules/ecs_service"

  service_name = "admin"
  environment  = var.environment

  vpc_id             = module.network.vpc_id
  vpc_cidr           = var.vpc_cidr
  public_subnet_ids  = module.network.public_subnet_ids
  private_subnet_ids = module.network.private_subnet_ids

  cluster_id   = module.ecs.cluster_id
  cluster_name = module.ecs.cluster_name

  container_image   = "${data.aws_ecr_repository.repos["admin"].repository_url}:latest"
  container_port    = 8080
  cpu               = 256
  memory            = 512
  desired_count     = 1
  health_check_path = "/health"

  environment_variables = [
    { name = "DB_HOST", value = module.database.db_endpoint },
    { name = "DB_PORT", value = "5432" },
    { name = "DB_USER", value = "retail_user" },
    { name = "ADMIN_USERNAME", value = var.admin_username },
  ]

  secret_arns = [
    {
      name      = "DB_PASSWORD"
      valueFrom = aws_secretsmanager_secret.db_password.arn
    },
    {
      name      = "ADMIN_PASSWORD"
      valueFrom = aws_secretsmanager_secret.admin_password.arn
    },
    {
      name      = "ADMIN_JWT_SECRET"
      valueFrom = aws_secretsmanager_secret.admin_jwt_secret.arn
    }
  ]

  execution_role_arn = data.aws_iam_role.labrole.arn
}
