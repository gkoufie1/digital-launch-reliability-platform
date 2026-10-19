data "aws_region" "current" {}

locals {
  region = data.aws_region.current.region

  alb_dims = { LoadBalancer = var.alb_arn_suffix }
  tg_dims  = { LoadBalancer = var.alb_arn_suffix, TargetGroup = var.target_group_arn_suffix }
  ecs_dims = { ClusterName = var.cluster_name, ServiceName = var.service_name }

  alarm_actions = [aws_sns_topic.alarms.arn]
}

# ---------------------------------------------------------------- Notifications

resource "aws_sns_topic" "alarms" {
  name              = "${var.name}-alarms"
  kms_master_key_id = "alias/aws/sns"
}

# Email subscriptions must be confirmed from the inbox before they deliver.
resource "aws_sns_topic_subscription" "email" {
  count = var.alarm_email == "" ? 0 : 1

  topic_arn = aws_sns_topic.alarms.arn
  protocol  = "email"
  endpoint  = var.alarm_email
}

# ---------------------------------------------------------------- Alarms

resource "aws_cloudwatch_metric_alarm" "target_5xx" {
  alarm_name          = "${var.name}-target-5xx"
  alarm_description   = "Application is returning 5xx errors."
  namespace           = "AWS/ApplicationELB"
  metric_name         = "HTTPCode_Target_5XX_Count"
  dimensions          = local.tg_dims
  statistic           = "Sum"
  period              = 60
  evaluation_periods  = 2
  threshold           = 5
  comparison_operator = "GreaterThanThreshold"
  treat_missing_data  = "notBreaching"
  alarm_actions       = local.alarm_actions
  ok_actions          = local.alarm_actions
}

resource "aws_cloudwatch_metric_alarm" "unhealthy_targets" {
  alarm_name          = "${var.name}-unhealthy-targets"
  alarm_description   = "At least one task is failing ALB health checks."
  namespace           = "AWS/ApplicationELB"
  metric_name         = "UnHealthyHostCount"
  dimensions          = local.tg_dims
  statistic           = "Maximum"
  period              = 60
  evaluation_periods  = 2
  threshold           = 0
  comparison_operator = "GreaterThanThreshold"
  treat_missing_data  = "notBreaching"
  alarm_actions       = local.alarm_actions
  ok_actions          = local.alarm_actions
}

resource "aws_cloudwatch_metric_alarm" "latency_p90" {
  alarm_name          = "${var.name}-latency-p90"
  alarm_description   = "p90 response time is above ${var.latency_threshold_seconds}s."
  namespace           = "AWS/ApplicationELB"
  metric_name         = "TargetResponseTime"
  dimensions          = local.tg_dims
  extended_statistic  = "p90"
  period              = 60
  evaluation_periods  = 3
  threshold           = var.latency_threshold_seconds
  comparison_operator = "GreaterThanThreshold"
  treat_missing_data  = "notBreaching"
  alarm_actions       = local.alarm_actions
  ok_actions          = local.alarm_actions
}

# ---------------------------------------------------------------- Dashboard

resource "aws_cloudwatch_dashboard" "this" {
  dashboard_name = var.name

  dashboard_body = jsonencode({
    widgets = [
      {
        type = "metric", x = 0, y = 0, width = 12, height = 6
        properties = {
          title  = "Requests and errors"
          region = local.region
          stat   = "Sum"
          period = 60
          metrics = [
            ["AWS/ApplicationELB", "RequestCount", "LoadBalancer", var.alb_arn_suffix, { label = "Requests" }],
            [".", "HTTPCode_Target_5XX_Count", "TargetGroup", var.target_group_arn_suffix, "LoadBalancer", var.alb_arn_suffix, { label = "Target 5xx", color = "#d62728" }],
            [".", "HTTPCode_ELB_5XX_Count", "LoadBalancer", var.alb_arn_suffix, { label = "ALB 5xx", color = "#ff7f0e" }],
          ]
        }
      },
      {
        type = "metric", x = 12, y = 0, width = 12, height = 6
        properties = {
          title  = "Target response time"
          region = local.region
          period = 60
          metrics = [
            ["AWS/ApplicationELB", "TargetResponseTime", "TargetGroup", var.target_group_arn_suffix, "LoadBalancer", var.alb_arn_suffix, { stat = "p50", label = "p50" }],
            ["...", { stat = "p90", label = "p90" }],
            ["...", { stat = "p99", label = "p99" }],
          ]
          annotations = { horizontal = [{ label = "Alarm", value = var.latency_threshold_seconds }] }
        }
      },
      {
        type = "metric", x = 0, y = 6, width = 8, height = 6
        properties = {
          title  = "Target health"
          region = local.region
          stat   = "Maximum"
          period = 60
          metrics = [
            ["AWS/ApplicationELB", "HealthyHostCount", "TargetGroup", var.target_group_arn_suffix, "LoadBalancer", var.alb_arn_suffix, { label = "Healthy", color = "#2ca02c" }],
            [".", "UnHealthyHostCount", ".", ".", ".", ".", { label = "Unhealthy", color = "#d62728" }],
          ]
        }
      },
      {
        type = "metric", x = 8, y = 6, width = 8, height = 6
        properties = {
          title  = "Service CPU and memory (%)"
          region = local.region
          stat   = "Average"
          period = 60
          metrics = [
            ["AWS/ECS", "CPUUtilization", "ClusterName", var.cluster_name, "ServiceName", var.service_name, { label = "CPU" }],
            [".", "MemoryUtilization", ".", ".", ".", ".", { label = "Memory" }],
          ]
          yAxis = { left = { min = 0, max = 100 } }
        }
      },
      {
        type = "metric", x = 16, y = 6, width = 8, height = 6
        properties = {
          title  = "Running tasks (Container Insights)"
          region = local.region
          stat   = "Average"
          period = 60
          metrics = [
            ["ECS/ContainerInsights", "RunningTaskCount", "ClusterName", var.cluster_name, "ServiceName", var.service_name, { label = "Running" }],
            [".", "DesiredTaskCount", ".", ".", ".", ".", { label = "Desired" }],
          ]
          yAxis = { left = { min = 0 } }
        }
      },
      {
        type = "alarm", x = 0, y = 12, width = 24, height = 3
        properties = {
          title = "Alarms"
          alarms = [
            aws_cloudwatch_metric_alarm.target_5xx.arn,
            aws_cloudwatch_metric_alarm.unhealthy_targets.arn,
            aws_cloudwatch_metric_alarm.latency_p90.arn,
          ]
        }
      },
      {
        type = "log", x = 0, y = 15, width = 24, height = 6
        properties = {
          title  = "Recent application logs"
          region = local.region
          view   = "table"
          query  = "SOURCE '${var.log_group_name}' | fields @timestamp, @message | sort @timestamp desc | limit 50"
        }
      },
    ]
  })
}
