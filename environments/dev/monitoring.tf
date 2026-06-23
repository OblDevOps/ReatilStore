locals {
  services     = ["ui", "catalog", "orders", "cart", "checkout", "admin"]
  cluster_name = module.ecs.cluster_name
}

# Alarma de disponibilidad: se activa cuando UI no tiene tareas corriendo
# Respuesta: revisar ECS → servicio ui → Events, y logs en /ecs/ui
resource "aws_cloudwatch_metric_alarm" "ui_no_running_tasks" {
  alarm_name          = "retailstore-${var.environment}-ui-sin-tareas"
  alarm_description   = "El servicio UI no tiene tareas corriendo. Revisar ECS y logs en /ecs/ui."
  comparison_operator = "LessThanThreshold"
  evaluation_periods  = 2
  metric_name         = "RunningTaskCount"
  namespace           = "ECS/ContainerInsights"
  period              = 60
  statistic           = "Minimum"
  threshold           = 1
  treat_missing_data  = "breaching"

  dimensions = {
    ClusterName = local.cluster_name
    ServiceName = "ui"
  }

  tags = {
    Name        = "retailstore-${var.environment}-ui-sin-tareas"
    Environment = var.environment
  }
}

# Alarma de rendimiento: se activa cuando el CPU de UI supera 80% por 10 minutos
# Respuesta: verificar que el auto scaling haya levantado tareas nuevas, si no revisar /ecs/ui
resource "aws_cloudwatch_metric_alarm" "ui_high_cpu" {
  alarm_name          = "retailstore-${var.environment}-ui-cpu-alta"
  alarm_description   = "CPU del servicio UI supera el 80% por 10 min. Verificar auto scaling y logs en /ecs/ui."
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 2
  metric_name         = "CPUUtilization"
  namespace           = "AWS/ECS"
  period              = 300
  statistic           = "Average"
  threshold           = 80
  treat_missing_data  = "notBreaching"

  dimensions = {
    ClusterName = local.cluster_name
    ServiceName = "ui"
  }

  tags = {
    Name        = "retailstore-${var.environment}-ui-cpu-alta"
    Environment = var.environment
  }
}

# Dashboard con métricas de todos los servicios
# Se puede ver en: CloudWatch → Dashboards → retailstore-dev
resource "aws_cloudwatch_dashboard" "main" {
  dashboard_name = "retailstore-${var.environment}"

  dashboard_body = jsonencode({
    widgets = [
      {
        type   = "metric"
        x      = 0
        y      = 0
        width  = 12
        height = 6
        properties = {
          title  = "CPU utilizada por servicio"
          region = "us-east-1"
          period = 300
          stat   = "Average"
          view   = "timeSeries"
          metrics = [
            for svc in local.services :
            ["ECS/ContainerInsights", "CpuUtilized", "ServiceName", svc, "ClusterName", local.cluster_name]
          ]
        }
      },
      {
        type   = "metric"
        x      = 12
        y      = 0
        width  = 12
        height = 6
        properties = {
          title  = "Memoria utilizada por servicio (MB)"
          region = "us-east-1"
          period = 300
          stat   = "Average"
          view   = "timeSeries"
          metrics = [
            for svc in local.services :
            ["ECS/ContainerInsights", "MemoryUtilized", "ServiceName", svc, "ClusterName", local.cluster_name]
          ]
        }
      },
      {
        type   = "metric"
        x      = 0
        y      = 6
        width  = 12
        height = 6
        properties = {
          title  = "Tareas corriendo por servicio"
          region = "us-east-1"
          period = 60
          stat   = "Minimum"
          view   = "singleValue"
          metrics = [
            for svc in local.services :
            ["ECS/ContainerInsights", "RunningTaskCount", "ServiceName", svc, "ClusterName", local.cluster_name]
          ]
        }
      },
      {
        type   = "alarm"
        x      = 12
        y      = 6
        width  = 12
        height = 6
        properties = {
          title = "Estado de alarmas"
          alarms = [
            aws_cloudwatch_metric_alarm.ui_no_running_tasks.arn,
            aws_cloudwatch_metric_alarm.ui_high_cpu.arn,
          ]
        }
      }
    ]
  })
}
