output "app_url" {
  description = "Public URL of the application."
  value       = "http://${module.alb.dns_name}"
}

output "health_url" {
  value = "http://${module.alb.dns_name}/api/health"
}

output "ecr_repository_url" {
  value = module.ecr.repository_url
}

output "deployed_image" {
  value = "${module.ecr.repository_url}:${var.image_tag}"
}

output "ecs_cluster" {
  value = module.ecs.cluster_name
}

output "ecs_service" {
  value = module.ecs.service_name
}

output "log_group" {
  value = module.ecs.log_group_name
}

output "dashboard_url" {
  value = "https://${var.aws_region}.console.aws.amazon.com/cloudwatch/home?region=${var.aws_region}#dashboards/dashboard/${module.monitoring.dashboard_name}"
}

output "availability_zones" {
  value = module.network.availability_zones
}
