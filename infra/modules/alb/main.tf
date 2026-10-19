resource "aws_security_group" "alb" {
  name        = "${var.name}-alb"
  description = "Public HTTP ingress to the application load balancer"
  vpc_id      = var.vpc_id

  tags = { Name = "${var.name}-alb" }
}

resource "aws_vpc_security_group_ingress_rule" "http" {
  #checkov:skip=CKV_AWS_260:Public demo site; narrow with var.allowed_cidrs for private testing
  for_each = toset(var.allowed_cidrs)

  security_group_id = aws_security_group.alb.id
  description       = "HTTP from ${each.value}"
  cidr_ipv4         = each.value
  ip_protocol       = "tcp"
  from_port         = 80
  to_port           = 80
}

# The ALB only needs to reach the tasks on the container port inside the VPC.
resource "aws_vpc_security_group_egress_rule" "to_targets" {
  security_group_id = aws_security_group.alb.id
  description       = "To ECS tasks on the container port"
  cidr_ipv4         = var.vpc_cidr_block
  ip_protocol       = "tcp"
  from_port         = var.target_port
  to_port           = var.target_port
}

resource "aws_lb" "this" {
  #checkov:skip=CKV_AWS_91:Access logs add S3 cost; CloudWatch ALB metrics cover the demo
  #checkov:skip=CKV_AWS_150:Temporary environment must be destroyable
  #checkov:skip=CKV2_AWS_20:No domain/certificate yet; HTTPS arrives with the Fastly phase
  #checkov:skip=CKV2_AWS_28:WAF (~$5+/month) out of scope for a temporary demo
  name               = "${var.name}-alb"
  load_balancer_type = "application"
  internal           = false
  security_groups    = [aws_security_group.alb.id]
  subnets            = var.public_subnet_ids

  drop_invalid_header_fields = true
  enable_deletion_protection = false # temporary environment; must be destroyable
}

resource "aws_lb_target_group" "this" {
  #checkov:skip=CKV_AWS_378:ALB-to-task traffic stays inside the VPC private subnets
  name        = "${var.name}-tg"
  port        = var.target_port
  protocol    = "HTTP"
  target_type = "ip"
  vpc_id      = var.vpc_id

  # Short drain keeps deployments and teardown fast.
  deregistration_delay = 30

  health_check {
    path                = var.health_check_path
    matcher             = "200"
    interval            = 15
    timeout             = 5
    healthy_threshold   = 2
    unhealthy_threshold = 3
  }
}

# Development only: plain HTTP. Production needs an HTTPS listener with an ACM
# certificate and origin protection once Fastly sits in front (see README).
resource "aws_lb_listener" "http" {
  #checkov:skip=CKV_AWS_2:Development-only HTTP listener; see comment above
  #checkov:skip=CKV_AWS_103:No TLS listener until a certificate exists
  load_balancer_arn = aws_lb.this.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.this.arn
  }
}
