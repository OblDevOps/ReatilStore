# Security group de Redis
resource "aws_security_group" "redis" {
  name        = "redis-${var.environment}-sg"
  description = "Permite conexiones a Redis desde la VPC"
  vpc_id      = var.vpc_id

  ingress {
    description = "Redis desde la VPC"
    from_port   = 6379
    to_port     = 6379
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
    Name        = "redis-${var.environment}-sg"
    Environment = var.environment
  }
}

resource "aws_cloudwatch_log_group" "redis" {
  name              = "/ecs/${var.environment}/redis"
  retention_in_days = 7

  tags = {
    Name        = "/ecs/${var.environment}/redis"
    Environment = var.environment
  }
}

resource "aws_ecs_task_definition" "redis" {
  family                   = "redis"
  requires_compatibilities = ["FARGATE"]
  network_mode             = "awsvpc"
  cpu                      = var.cpu
  memory                   = var.memory
  execution_role_arn       = var.execution_role_arn

  container_definitions = jsonencode([
    {
      name      = "redis"
      image     = "redis:7-alpine"
      essential = true
      portMappings = [
        {
          containerPort = 6379
          protocol      = "tcp"
        }
      ]
      logConfiguration = {
        logDriver = "awslogs"
        options = {
          "awslogs-group"         = "/ecs/${var.environment}/redis"
          "awslogs-region"        = var.aws_region
          "awslogs-stream-prefix" = "ecs"
        }
      }
    }
  ])

  tags = {
    Name        = "redis"
    Environment = var.environment
  }
}

resource "aws_lb" "redis" {
  name               = "redis-${var.environment}-nlb"
  internal           = true
  load_balancer_type = "network"
  subnets            = var.private_subnet_ids

  tags = {
    Name        = "redis-${var.environment}-nlb"
    Environment = var.environment
  }
}

resource "aws_lb_target_group" "redis" {
  name        = "redis-${var.environment}-tg"
  port        = 6379
  protocol    = "TCP"
  vpc_id      = var.vpc_id
  target_type = "ip"

  health_check {
    protocol            = "TCP"
    port                = 6379
    healthy_threshold   = 2
    unhealthy_threshold = 2
    interval            = 30
  }

  tags = {
    Name        = "redis-${var.environment}-tg"
    Environment = var.environment
  }
}

resource "aws_lb_listener" "redis" {
  load_balancer_arn = aws_lb.redis.arn
  port              = 6379
  protocol          = "TCP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.redis.arn
  }
}

resource "aws_ecs_service" "redis" {
  name            = "redis"
  cluster         = var.cluster_id
  task_definition = aws_ecs_task_definition.redis.arn
  desired_count   = 1
  launch_type     = "FARGATE"

  network_configuration {
    subnets          = var.private_subnet_ids
    security_groups  = [aws_security_group.redis.id]
    assign_public_ip = false
  }

  load_balancer {
    target_group_arn = aws_lb_target_group.redis.arn
    container_name   = "redis"
    container_port   = 6379
  }

  depends_on = [aws_lb_listener.redis]

  tags = {
    Name        = "redis"
    Environment = var.environment
  }
}


