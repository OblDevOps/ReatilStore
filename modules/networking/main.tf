# VPC principal: la red base donde vive toda la infraestructura
resource "aws_vpc" "main" {
  cidr_block           = var.vpc_cidr
  enable_dns_support   = true
  enable_dns_hostnames = true
  tags = {
    Name        = var.vpc_name
    Environment = var.environment
  }
}

# Internet Gateway: la puerta de entrada/salida a internet de la VPC
resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.main.id
  tags = {
    Name        = "${var.vpc_name}-igw"
    Environment = var.environment
  }
}

# Subnets públicas: donde vive el ALB y los NAT (tienen salida directa a internet)
resource "aws_subnet" "public_subnet" {
  count             = length(var.public_subnets)
  vpc_id            = aws_vpc.main.id
  cidr_block        = var.public_subnets[count.index]
  availability_zone = var.availability_zones[count.index]
  tags = {
    Name        = "${var.vpc_name}-public-${count.index + 1}"
    Environment = var.environment
  }
}

# Subnets privadas: donde corren los microservicios y la base de datos (sin acceso directo desde internet)
resource "aws_subnet" "private_subnet" {
  count                   = length(var.private_subnets)
  vpc_id                  = aws_vpc.main.id
  cidr_block              = var.private_subnets[count.index]
  availability_zone       = var.availability_zones[count.index]
  map_public_ip_on_launch = false # Evita asignar IP pública a lo que se cree en la subnet
  tags = {
    Name        = "${var.vpc_name}-private-${count.index + 1}"
    Environment = var.environment
  }
}

# Tabla de ruteo pública: una sola, compartida por todas las subnets públicas
resource "aws_route_table" "public_route_table" {
  vpc_id = aws_vpc.main.id
  tags = {
    Name        = "${var.vpc_name}-public-route-table"
    Environment = var.environment
  }
}

# Ruta pública: dirige todo el tráfico de salida (0.0.0.0/0) hacia el Internet Gateway
resource "aws_route" "public_route" {
  route_table_id         = aws_route_table.public_route_table.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.igw.id
}

# Asocia la tabla pública a cada subnet pública
resource "aws_route_table_association" "public_subnet_association" {
  count          = length(var.public_subnets)
  subnet_id      = aws_subnet.public_subnet[count.index].id
  route_table_id = aws_route_table.public_route_table.id
}

# Elastic IPs: una IP pública fija por cada NAT Gateway
resource "aws_eip" "nat_eip" {
  count  = length(var.public_subnets)
  domain = "vpc"
  tags = {
    Name        = "${var.vpc_name}-nat-eip-${count.index + 1}"
    Environment = var.environment
  }
}

# NAT Gateways: uno por AZ (alta disponibilidad); viven en las subnets públicas pero dan salida a las privadas
resource "aws_nat_gateway" "nat_gw" {
  count         = length(var.public_subnets)
  allocation_id = aws_eip.nat_eip[count.index].id
  subnet_id     = aws_subnet.public_subnet[count.index].id
  tags = {
    Name        = "${var.vpc_name}-nat-gw-${count.index + 1}"
    Environment = var.environment
  }
}

# Tablas de ruteo privadas: una por subnet privada (para que cada una pueda usar el NAT de su propia zona)
resource "aws_route_table" "private_route_table" {
  count  = length(var.private_subnets)
  vpc_id = aws_vpc.main.id
  tags = {
    Name        = "${var.vpc_name}-private-rt-${count.index + 1}"
    Environment = var.environment
  }
}

# Ruta privada: dirige el tráfico de salida de cada subnet privada hacia el NAT de su misma zona
resource "aws_route" "private_route" {
  count                  = length(var.private_subnets)
  route_table_id         = aws_route_table.private_route_table[count.index].id
  destination_cidr_block = "0.0.0.0/0"
  nat_gateway_id         = aws_nat_gateway.nat_gw[count.index].id
}

# Asocia cada tabla privada a su subnet privada correspondiente
resource "aws_route_table_association" "private_subnet_association" {
  count          = length(var.private_subnets)
  subnet_id      = aws_subnet.private_subnet[count.index].id
  route_table_id = aws_route_table.private_route_table[count.index].id
}
