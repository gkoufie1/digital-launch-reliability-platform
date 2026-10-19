locals {
  name           = "digital-launch-${var.environment}"
  container_port = 3000
}

module "network" {
  source = "../../modules/network"

  name               = local.name
  cidr_block         = var.vpc_cidr_block
  single_nat_gateway = var.single_nat_gateway
}

module "ecr" {
  source = "../../modules/ecr"

  name = "digital-launch-web"
}

module "alb" {
  source = "../../modules/alb"

  name              = local.name
  vpc_id            = module.network.vpc_id
  vpc_cidr_block    = module.network.vpc_cidr_block
  public_subnet_ids = module.network.public_subnet_ids
  target_port       = local.container_port
  allowed_cidrs     = var.allowed_cidrs
}

module "ecs" {
  source = "../../modules/ecs"

  name                             = local.name
  vpc_id                           = module.network.vpc_id
  private_subnet_ids               = module.network.private_subnet_ids
  alb_security_group_id            = module.alb.security_group_id
  target_group_arn                 = module.alb.target_group_arn
  alb_request_count_resource_label = "${module.alb.arn_suffix}/${module.alb.target_group_arn_suffix}"
  ecr_repository_arn               = module.ecr.repository_arn
  image                            = "${module.ecr.repository_url}:${var.image_tag}"
  container_port                   = local.container_port
  desired_count                    = var.desired_count
  min_capacity                     = var.desired_count
  max_capacity                     = var.max_capacity
  container_insights               = var.container_insights

  # The target group must be attached to a listener before a service can use it.
  depends_on = [module.alb]
}

module "monitoring" {
  source = "../../modules/monitoring"

  name                    = local.name
  alb_arn_suffix          = module.alb.arn_suffix
  target_group_arn_suffix = module.alb.target_group_arn_suffix
  cluster_name            = module.ecs.cluster_name
  service_name            = module.ecs.service_name
  log_group_name          = module.ecs.log_group_name
  alarm_email             = var.alarm_email
}
