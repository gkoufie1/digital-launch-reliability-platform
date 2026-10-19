# Infrastructure

Terraform for the AWS runtime: a VPC across two availability zones, a public Application Load Balancer, and two ECS Fargate tasks in private subnets, with images in ECR and logs, metrics, alarms and a dashboard in CloudWatch.

This is a **temporary environment**. It is built for a working session or a demo, then destroyed. Everything is designed to be torn down completely with `terraform destroy`.

## Architecture

```
Internet
   │  HTTP :80
   ▼
Application Load Balancer ── public subnets (us-east-1a, us-east-1b)
   │  :3000, health check /api/health
   ▼
ECS Fargate service, 2–4 tasks ── private subnets, no public IPs
   │  HTTPS :443 out only
   ├─► NAT gateway (single, shared) ─► ECR API, CloudWatch Logs
   └─► S3 gateway endpoint ─► ECR image layers (no NAT data charge)
```

| Module | What it creates |
|---|---|
| `network` | VPC `10.40.0.0/16`, 2 public + 2 private subnets, internet gateway, one NAT gateway, S3 gateway endpoint, locked-down default security group |
| `ecr` | Image repository: immutable tags, scan on push, keeps the last 10 images |
| `alb` | Load balancer, target group (health check `/api/health`), HTTP listener |
| `ecs` | Cluster with Container Insights, task definition, service, least-privilege IAM, autoscaling |
| `monitoring` | Dashboard, alarms (5xx, unhealthy targets, p90 latency), SNS topic for alerts |

## Reliability features

- **Two AZs.** The baseline of two tasks is spread across `us-east-1a` and `us-east-1b`.
- **Zero-downtime deploys.** New tasks must pass health checks before old ones stop (`minimum_healthy_percent = 100`).
- **Automatic rollback.** The ECS deployment circuit breaker rolls back a release whose tasks never become healthy.
- **Two health checks.** The ALB checks `/api/health`, and the container has its own check that ECS uses to replace failed tasks.
- **Autoscaling** from 2 to 4 tasks on CPU (60%) or requests per task (1,000/min).
- **Verified applies.** `wait_for_steady_state` makes `terraform apply` succeed only once the service is stable.

## Security

- Tasks run in private subnets with no public IP, accept traffic only from the ALB security group, and can only make outbound HTTPS calls.
- The task execution role can pull from this one repository and write to this one log group. The application role has no permissions.
- ECR tags are immutable, and deployments use versioned tags (git SHA). `latest` is rejected.
- State is stored in S3 with versioning, encryption, public access blocked, TLS-only access and native S3 locking.
- Checkov: 125 checks pass. 16 are accepted risks, documented inline with `#checkov:skip` comments. Most are HTTPS/TLS (planned for the Fastly phase), KMS customer keys, WAF, and deletion protection, which would block teardown.

## Cost

Approximate us-east-1 cost **while running**:

| Resource | Per hour |
|---|---|
| Application Load Balancer | ~$0.03 |
| NAT gateway (one) | ~$0.045 |
| Fargate, 2 × (0.25 vCPU, 0.5 GB) | ~$0.025 |
| Public IPv4 addresses (~3) | ~$0.015 |
| CloudWatch, ECR, data transfer | cents |
| **Total** | **≈ $0.12/hour (≈ $3/day)** |

One NAT gateway instead of one per AZ saves ~$33/month. The trade-off is that if `us-east-1a` fails, tasks in `us-east-1b` lose outbound access. Set `single_nat_gateway = false` for full AZ independence.

## Prerequisites

- Terraform ≥ 1.10, AWS CLI v2, Docker
- AWS credentials. This project uses the `kwesi` profile: `export AWS_PROFILE=kwesi`

## One-time setup: state bucket

```bash
cd infra/bootstrap
terraform init
terraform apply
cd ../envs/dev
cp backend.hcl.example backend.hcl   # set the bucket name from the bootstrap output
terraform init -backend-config=backend.hcl
```

## Build a session

Run from the repository root:

```bash
export AWS_PROFILE=kwesi
TAG=$(git rev-parse --short HEAD)

# 1. Create the image repository first.
terraform -chdir=infra/envs/dev apply -target=module.ecr -var image_tag=$TAG

# 2. Build the image and push it, tagged with the git SHA.
scripts/push-image.sh $TAG

# 3. Create everything else (about 5–10 minutes).
terraform -chdir=infra/envs/dev apply -var image_tag=$TAG

# 4. Verify.
curl -i "$(terraform -chdir=infra/envs/dev output -raw health_url)"
```

To deploy a new version, commit, run `scripts/push-image.sh`, then `terraform apply -var image_tag=<new sha>`. ECS rolls the new version out with no downtime.

## End a session: destroy

```bash
terraform -chdir=infra/envs/dev destroy -var image_tag=$TAG
```

This removes everything, including pushed images (`force_delete`). The state bucket stays and costs fractions of a cent. To remove it after the project is finished:

```bash
terraform -chdir=infra/bootstrap apply -var force_destroy=true
terraform -chdir=infra/bootstrap destroy -var force_destroy=true
```

**Always confirm the teardown.** No load balancers or NAT gateways should remain:

```bash
aws elbv2 describe-load-balancers --query 'LoadBalancers[].LoadBalancerName'
aws ec2 describe-nat-gateways --filter Name=state,Values=available --query 'NatGateways[].NatGatewayId'
```
