environment = "dev"

vpc_name = "retailstore-dev"

vpc_cidr = "10.0.0.0/16"

public_subnets = ["10.0.1.0/24", "10.0.2.0/24"]

private_subnets = ["10.0.3.0/24", "10.0.4.0/24"]

availability_zones = ["us-east-1a", "us-east-1b"]

repository_names = ["ui", "catalog", "cart", "checkout", "orders", "admin", "db"]

cluster_name = "retailstore-dev"

admin_username = "admin"
