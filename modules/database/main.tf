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
        { name = "POSTGRES_DB", value = var.db_name }
      ]
      secrets = [
        {
          name      = "POSTGRES_PASSWORD"
          valueFrom = var.db_secret_arn
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
  load_balancer_type = "network" #trabaja en tcp, es necesario para postgres
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

# listner Tcp: el network loas balancer escucha en 5432 y reenvía al target group. como en ui pero con tcp en vz de http
resource "aws_lb_listener" "db" {
  load_balancer_arn = aws_lb.db.arn
  port              = 5432
  protocol          = "TCP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.db.arn
  }
}

# ECS Service de Postgres: mantiene la tarea corriendo y la registra en el network load balancer
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

  depends_on = [aws_lb_listener.db]

  tags = {
    Name        = "postgres"
    Environment = var.environment
  }
}
