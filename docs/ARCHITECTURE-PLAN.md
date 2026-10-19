# Architecture and delivery plan

## Target request path
Browser -> Fastly CDN (Phase 2) -> AWS Application Load Balancer -> ECS Fargate Next.js tasks in private subnets (two availability zones).

AWS ECR stores application images. CloudWatch receives ECS logs and metrics. Terraform owns infrastructure; GitHub Actions owns application deployments. Sentry provides application-level error tracking. Static asset origin separation and private S3 integration are deferred until after the core application path is validated.

## Terraform module plan
- networking: VPC, public/private subnets across 2 AZs, egress via NAT or endpoints after cost evaluation
- security: security groups, least-privilege IAM, GitHub OIDC trust
- ecr: repository, scanning and lifecycle
- alb: listeners, target groups, health checks
- ecs: cluster, task definition, service, autoscaling, rollback controls
- monitoring: CloudWatch logs, metrics and alarms
- fastly (later): edge service, backend, caching and purging

## Planned incidents
1. Traffic surge: k6 and ECS autoscaling
2. Broken release: ECS deployment rollback
3. CDN stale content: purge and cache verification
4. Task failure: service replacement and availability checks
5. Application latency: Sentry traces, CloudWatch metrics, root-cause report

## Phase 1 acceptance criteria
Working Next.js container, successful `/api/health` HTTP 200, ECR image, two private ECS tasks behind an ALB, CloudWatch logs, documented cost controls, clean Terraform destroy.

## Important implementation notes
Use immutable image digests for deployments, approval gates for production, and health/readiness checks that cannot be served from CDN cache. Avoid placing AWS access keys in GitHub. For future Fastly integration, protect direct ALB origin access and configure private S3 access correctly.
