variable "name" {
  description = "Name for the cluster, service, task family and related resources."
  type        = string
}

variable "vpc_id" {
  type = string
}

variable "private_subnet_ids" {
  type = list(string)
}

variable "alb_security_group_id" {
  type = string
}

variable "target_group_arn" {
  type = string
}

variable "alb_request_count_resource_label" {
  description = "\"<alb arn_suffix>/<target group arn_suffix>\" for request-count scaling."
  type        = string
}

variable "ecr_repository_arn" {
  type = string
}

variable "image" {
  description = "Full image reference, e.g. <repo-url>:<git-sha>."
  type        = string
}

variable "container_port" {
  type    = number
  default = 3000
}

variable "cpu" {
  description = "Task CPU units (256 = 0.25 vCPU)."
  type        = number
  default     = 256
}

variable "memory" {
  description = "Task memory in MiB."
  type        = number
  default     = 512
}

variable "desired_count" {
  type    = number
  default = 2
}

variable "min_capacity" {
  type    = number
  default = 2
}

variable "max_capacity" {
  type    = number
  default = 4
}

variable "cpu_target_percent" {
  type    = number
  default = 60
}

variable "requests_per_target" {
  description = "Target ALB requests per task per minute before scaling out."
  type        = number
  default     = 1000
}

variable "log_retention_days" {
  type    = number
  default = 7
}

variable "container_insights" {
  description = "Enable CloudWatch Container Insights (small extra metrics cost)."
  type        = bool
  default     = true
}
