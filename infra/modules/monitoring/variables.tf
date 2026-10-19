variable "name" {
  type = string
}

variable "alb_arn_suffix" {
  type = string
}

variable "target_group_arn_suffix" {
  type = string
}

variable "cluster_name" {
  type = string
}

variable "service_name" {
  type = string
}

variable "log_group_name" {
  type = string
}

variable "alarm_email" {
  description = "Email for alarm notifications; empty disables the subscription."
  type        = string
  default     = ""
}

variable "latency_threshold_seconds" {
  type    = number
  default = 1
}
