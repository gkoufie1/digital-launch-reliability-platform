variable "aws_region" {
  type    = string
  default = "us-east-1"
}

variable "environment" {
  type    = string
  default = "dev"
}

variable "image_tag" {
  description = "Image tag to deploy (the git short SHA pushed by scripts/push-image.sh)."
  type        = string

  validation {
    condition     = length(var.image_tag) > 0 && var.image_tag != "latest"
    error_message = "Deploy an immutable, versioned tag (e.g. a git SHA), not empty or \"latest\"."
  }
}

variable "vpc_cidr_block" {
  type    = string
  default = "10.40.0.0/16"
}

variable "single_nat_gateway" {
  description = "One shared NAT gateway (cheaper) vs. one per AZ (resilient)."
  type        = bool
  default     = true
}

variable "allowed_cidrs" {
  description = "IPv4 CIDRs allowed to reach the ALB. Narrow to your IP (x.x.x.x/32) for private testing."
  type        = list(string)
  default     = ["0.0.0.0/0"]
}

variable "desired_count" {
  description = "Baseline (and minimum) number of tasks; 2 keeps one per AZ."
  type        = number
  default     = 2
}

variable "max_capacity" {
  description = "Autoscaling ceiling."
  type        = number
  default     = 4
}

variable "container_insights" {
  type    = bool
  default = true
}

variable "alarm_email" {
  description = "Email for CloudWatch alarm notifications (confirm the subscription email)."
  type        = string
  default     = ""
}
