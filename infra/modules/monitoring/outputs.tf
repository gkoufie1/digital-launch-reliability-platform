output "dashboard_name" {
  value = aws_cloudwatch_dashboard.this.dashboard_name
}

output "alarm_topic_arn" {
  value = aws_sns_topic.alarms.arn
}
