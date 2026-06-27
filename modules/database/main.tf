# Security group de Postgres. acepta conexiones al puerto 5432 desde la VPC
resource "aws_security_group" "db" {
  name        = "postgres-${var.environment}-db-sg"
  description = "Permite conexiones a Postgres desde la VPC"
  vpc_id      = var.vpc_id

  ingress {
    description = "PostgreSQL desde la VPC"
    from_port   = 5432
    to_port     = 5432
    protocol    = "tcp"
    cidr_blocks = [var.vpc_cidr]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name        = "postgres-${var.environment}-db-sg"
    Environment = var.environment
  }
}

# Security group para EFS - permite NFS desde la VPC
resource "aws_security_group" "efs" {
  name        = "postgres-${var.environment}-efs-sg"
  description = "Permite NFS desde la VPC para EFS de Postgres"
  vpc_id      = var.vpc_id

  ingress {
    description = "NFS desde la VPC"
    from_port   = 2049
    to_port     = 2049
    protocol    = "tcp"
    cidr_blocks = [var.vpc_cidr]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name        = "postgres-${var.environment}-efs-sg"
    Environment = var.environment
  }
}

# EFS File System para persistencia de datos de Postgres
resource "aws_efs_file_system" "postgres" {
  creation_token = "postgres-${var.environment}"
  encrypted      = true

  tags = {
    Name        = "postgres-${var.environment}-efs"
    Environment = var.environment
  }
}

# Mount target por cada subnet privada para que ECS pueda montar EFS desde cualquier AZ
resource "aws_efs_mount_target" "postgres" {
  count = length(var.private_subnet_ids)

  file_system_id  = aws_efs_file_system.postgres.id
  subnet_id       = var.private_subnet_ids[count.index]
  security_groups = [aws_security_group.efs.id]
}

# Access point con UID/GID del usuario postgres en alpine (70/70)
resource "aws_efs_access_point" "postgres" {
  file_system_id = aws_efs_file_system.postgres.id

  posix_user {
    uid = 70
    gid = 70
  }

  root_directory {
    path = "/pgdata"
    creation_info {
      owner_uid   = 70
      owner_gid   = 70
      permissions = "700"
    }
  }

  tags = {
    Name        = "postgres-${var.environment}-ap"
    Environment = var.environment
  }
}

resource "aws_cloudwatch_log_group" "db" {
  name              = "/ecs/${var.environment}/postgres"
  retention_in_days = 7

  tags = {
    Name        = "/ecs/${var.environment}/postgres"
    Environment = var.environment
  }
}

# task definition de postgres
resource "aws_ecs_task_definition" "db" {
  family                   = "postgres"
  requires_compatibilities = ["FARGATE"]
  network_mode             = "awsvpc"
  cpu                      = var.cpu
  memory                   = var.memory
  execution_role_arn       = var.execution_role_arn

  volume {
    name = "postgres-data"

    efs_volume_configuration {
      file_system_id     = aws_efs_file_system.postgres.id
      transit_encryption = "ENABLED"

      authorization_config {
        access_point_id = aws_efs_access_point.postgres.id
        iam             = "DISABLED"
      }
    }
  }

  container_definitions = jsonencode([
    {
      name      = "postgres"
      image     = var.container_image
      essential = true

      portMappings = [
        {
          containerPort = 5432
          protocol      = "tcp"
        }
      ]

      environment = [
        { name = "POSTGRES_USER", value = var.db_user },
        { name = "POSTGRES_DB", value = var.db_name },
        # Subdirectorio dentro del mount para evitar conflictos con archivos del sistema de EFS
        { name = "PGDATA", value = "/var/lib/postgresql/data/pgdata" }
      ]

      secrets = [
        {
          name      = "POSTGRES_PASSWORD"
          valueFrom = var.db_secret_arn
        }
      ]

      mountPoints = [
        {
          sourceVolume  = "postgres-data"
          containerPath = "/var/lib/postgresql/data"
          readOnly      = false
        }
      ]

      logConfiguration = {
        logDriver = "awslogs"
        options = {
          "awslogs-group"         = "/ecs/${var.environment}/postgres"
          "awslogs-region"        = var.aws_region
          "awslogs-stream-prefix" = "ecs"
        }
      }
    }
  ])

  tags = {
    Name        = "postgres"
    Environment = var.environment
  }
}

# network load balancer interno para postgres (usa tcp)
resource "aws_lb" "db" {
  name               = "postgres-${var.environment}-nlb"
  internal           = true
  load_balancer_type = "network"
  subnets            = var.private_subnet_ids

  tags = {
    Name        = "postgres-${var.environment}-nlb"
    Environment = var.environment
  }
}

# Target Group TCP para Postgres
resource "aws_lb_target_group" "db" {
  name        = "postgres-${var.environment}-tg"
  port        = 5432
  protocol    = "TCP"
  vpc_id      = var.vpc_id
  target_type = "ip"

  health_check {
    protocol            = "TCP"
    port                = 5432
    healthy_threshold   = 2
    unhealthy_threshold = 2
    interval            = 30
  }

  tags = {
    Name        = "postgres-${var.environment}-tg"
    Environment = var.environment
  }
}

resource "aws_lb_listener" "db" {
  load_balancer_arn = aws_lb.db.arn
  port              = 5432
  protocol          = "TCP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.db.arn
  }
}

# ECS Service de Postgres
resource "aws_ecs_service" "db" {
  name            = "postgres"
  cluster         = var.cluster_id
  task_definition = aws_ecs_task_definition.db.arn
  desired_count   = 1
  launch_type     = "FARGATE"

  network_configuration {
    subnets          = var.private_subnet_ids
    security_groups  = [aws_security_group.db.id]
    assign_public_ip = false
  }

  load_balancer {
    target_group_arn = aws_lb_target_group.db.arn
    container_name   = "postgres"
    container_port   = 5432
  }

  # Esperar a que los mount targets estén listos antes de arrancar el servicio
  depends_on = [aws_lb_listener.db, aws_efs_mount_target.postgres]

  tags = {
    Name        = "postgres"
    Environment = var.environment
  }
}
