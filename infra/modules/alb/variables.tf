variable "name" {
  description = "Name prefix (ALB and target group names are limited to 32 characters)."
  type        = string
}

variable "vpc_id" {
  type = string
}

variable "vpc_cidr_block" {
  type = string
}

variable "public_subnet_ids" {
  type = list(string)
}

variable "target_port" {
  description = "Port the containers listen on."
  type        = number
}

variable "health_check_path" {
  type    = string
  default = "/api/health"
}

variable "allowed_cidrs" {
  description = "IPv4 CIDRs allowed to reach the ALB on port 80. Narrow to your own IP for private testing."
  type        = list(string)
  default     = ["0.0.0.0/0"]
}
