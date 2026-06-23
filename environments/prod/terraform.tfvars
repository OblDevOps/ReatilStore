environment = "prod"

vpc_name = "retailstore-prod"

vpc_cidr = "10.2.0.0/16"

public_subnets = ["10.2.1.0/24", "10.2.2.0/24"]

private_subnets = ["10.2.3.0/24", "10.2.4.0/24"]

availability_zones = ["us-east-1a", "us-east-1b"]

repository_names = ["ui", "catalog", "cart", "checkout", "orders", "admin", "db"]

cluster_name = "retailstore-prod"

admin_username = "admin"
