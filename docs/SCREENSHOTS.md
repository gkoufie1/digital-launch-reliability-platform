# Screenshot checklist

Evidence for the portfolio, captured while the stack is running and then kept after `terraform destroy`. Save images to [`docs/screenshots/`](screenshots/) using the file names below, so they sort in story order and the README can embed them.

⭐ = highest value. If time is short, capture these first.

**Before you start**
- Console region (top right): **US East (N. Virginia) / us-east-1**.
- Generate traffic for ~10 minutes first so the graphs have data (see [Generate traffic](#generate-traffic)).
- Use one browser theme and a wide window throughout.
- Crop or blur your email. The 12-digit account ID is not secret, but blurring it looks tidy.

**Terminal setup** (PowerShell, from the repository root)
```powershell
$env:AWS_PROFILE = "kwesi"
$URL = terraform -chdir=infra/envs/dev output -raw app_url
$TAG = (terraform -chdir=infra/envs/dev output -raw deployed_image).Split(":")[-1]
```

---

## 1. GitHub (no AWS needed)

- [ ] `01-github-ci-green.png`: **Actions → CI** → a passing run showing both jobs
- [ ] `02-github-pr-checks.png`: **Pull requests → Closed → #1**, the passing checks at the bottom
- [ ] `03-github-ci-caught-bad-update.png`: the failed CI run on Dependabot PR #3 (lint broke on TypeScript 7)
- [ ] `04-github-repo-home.png`: repository home page with the README and CI badge

## 2. Terminal

- [ ] `10-checkov.png`: security scan, 125 passed / 0 failed
  ```powershell
  checkov -d infra --framework terraform --compact --quiet
  ```
- [ ] `11-terraform-apply-complete.png`: the end of `terraform apply` with "Apply complete!" and the outputs
- [ ] `12-terraform-outputs.png`
  ```powershell
  terraform -chdir=infra/envs/dev output
  ```
- [ ] `13-health-check-200.png`: use `curl.exe`, not `curl`, in PowerShell
  ```powershell
  curl.exe -i "$URL/api/health"
  ```
- [ ] ⭐ `14-ecs-service-status.png`: 2 desired, 2 running, rollout COMPLETED
  ```powershell
  aws ecs describe-services --cluster digital-launch-dev --services digital-launch-dev --query 'services[0].{Service:serviceName,Status:status,Desired:desiredCount,Running:runningCount,Rollout:deployments[0].rolloutState,LaunchType:launchType}' --output table
  ```
- [ ] ⭐ `15-targets-healthy-two-azs.png`
  ```powershell
  aws elbv2 describe-target-health --target-group-arn $(aws elbv2 describe-target-groups --names digital-launch-dev-tg --query 'TargetGroups[0].TargetGroupArn' --output text) --query 'TargetHealthDescriptions[].{IP:Target.Id,AZ:Target.AvailabilityZone,Port:Target.Port,Health:TargetHealth.State}' --output table
  ```
- [ ] ⭐ `16-terraform-no-drift.png`: ends with "found no differences, so no changes are needed"
  ```powershell
  terraform -chdir=infra/envs/dev plan -var image_tag=$TAG
  ```
- [ ] `17-ecr-images.png`: the image tagged with the git commit
  ```powershell
  aws ecr describe-images --repository-name digital-launch-web --query 'imageDetails[].{Tag:imageTags[0],Pushed:imagePushedAt,SizeMB:imageSizeInBytes}' --output table
  ```

## 3. AWS console

| ✓ | File | Where | What to show |
|---|---|---|---|
| ✅ | `20-live-site.png` | Browser → `$URL` | The page, with the AWS URL in the address bar |
| ✅ | `21-live-health-json.png` | Browser → `$URL/api/health` | The JSON response |
| ✅ | ⭐ `22-ecs-cluster-services.png` | [ECS → Clusters → digital-launch-dev](https://us-east-1.console.aws.amazon.com/ecs/v2/clusters/digital-launch-dev/services?region=us-east-1) → **Services** | Cluster active, 2 tasks running, service 2/2 |
| ✅ | ⭐ `23-ecs-tasks.png` | Cluster → **Tasks** tab | Both tasks Running and Healthy (enable the AZ column via ⚙️ to show one per AZ) |
| [ ] | `24-ecs-deployments.png` | Same service → **Deployments** tab | Completed deployment, circuit breaker enabled |
| ✅ | `25-ecs-autoscaling.png` | Same service → **Configuration and networking** → Service auto scaling | Min 2 / max 4, CPU and request-count policies |
| ✅ | ⭐ `26-target-group-healthy.png` | [EC2 → Target Groups → digital-launch-dev-tg](https://us-east-1.console.aws.amazon.com/ec2/home?region=us-east-1#TargetGroups:search=digital-launch-dev-tg) → **Targets** | Both targets healthy, in two AZs |
| ✅ | `27-load-balancer.png` | [EC2 → Load Balancers → digital-launch-dev-alb](https://us-east-1.console.aws.amazon.com/ec2/home?region=us-east-1#LoadBalancers:search=digital-launch-dev-alb) | Active, 2 AZs; **Listeners** tab shows HTTP:80 |
| [ ] | ⭐ `28-vpc-resource-map.png` | [VPC → Your VPCs](https://us-east-1.console.aws.amazon.com/vpcconsole/home?region=us-east-1#vpcs:search=digital-launch-dev-vpc) → select `digital-launch-dev-vpc` → **Resource map** | Subnets, route tables, NAT gateway, S3 endpoint |
| ✅ | `29-ecr-repository.png` | [ECR → Private repositories](https://us-east-1.console.aws.amazon.com/ecr/private-registry/repositories?region=us-east-1) → `digital-launch-web` | Image tagged with the git SHA |
| ✅ | `30-ecr-scan-findings.png` | Same repo → click the image tag → **Vulnerabilities** | Scan results (see [Known findings](#known-findings)) |
| [ ] | `31-iam-least-privilege.png` | [IAM → Roles → digital-launch-dev-task-execution](https://us-east-1.console.aws.amazon.com/iam/home#/roles/details/digital-launch-dev-task-execution) → expand `pull-image-and-write-logs` | Access to one repository and one log group only |
| ✅ | ⭐ `32-cloudwatch-dashboard.png` | [CloudWatch → Dashboards → digital-launch-dev](https://us-east-1.console.aws.amazon.com/cloudwatch/home?region=us-east-1#dashboards/dashboard/digital-launch-dev), time range **1h** | Requests, latency, healthy hosts, CPU/memory, task count |
| ✅ | `33-cloudwatch-alarms.png` | [CloudWatch → Alarms](https://us-east-1.console.aws.amazon.com/cloudwatch/home?region=us-east-1#alarmsV2:), filter `digital-launch-dev` + State = OK | Project and scale-out alarms all OK. Unfiltered, autoscaling's scale-in `AlarmLow` alarms show "In alarm" whenever the service sits at its minimum; that is expected, not a fault |
| [ ] | `34-cloudwatch-logs.png` | [CloudWatch → Log groups → /ecs/digital-launch-dev](https://us-east-1.console.aws.amazon.com/cloudwatch/home?region=us-east-1#logsV2:log-groups/log-group/$252Fecs$252Fdigital-launch-dev) → a log stream | Next.js startup lines |
| ✅ | `35-ecs-container-insights.png` | ECS cluster → **Metrics** tab → **Container Insights metrics** | CPU, memory and network per task |

## 4. Incident drills

Each drill is one story: a **before** shot, the **failure**, the **automatic recovery**, and the **after** shot.

| ✓ | File | Drill | Capture |
|---|---|---|---|
| [ ] | ⭐ `40-surge-dashboard.png` | Traffic surge (k6) | Dashboard: requests spike, running tasks 2 → 4, latency holds |
| [ ] | `41-surge-ecs-events.png` | Traffic surge | ECS service → **Events**: scale-out messages |
| [ ] | ⭐ `42-rollback-deployments.png` | Broken release | ECS **Deployments**: circuit breaker triggered and rolled back |
| [ ] | `43-rollback-site-up.png` | Broken release | `/api/health` still 200 during the failed rollout |
| [ ] | `44-task-failure-events.png` | Task failure | ECS **Events**: task stopped, replacement started |
| [ ] | `45-task-failure-targets.png` | Task failure | Target group: new target registering, then healthy |
| [ ] | `46-alarm-in-alarm.png` | Any | An alarm in the "In alarm" state |
| [ ] | `47-alarm-email.png` | Any | The alert email in Gmail (crop the address) |

## 5. Teardown proof

- [ ] ⭐ `50-terraform-destroy.png`: the end of `terraform destroy`, "Destroy complete!"
  ```powershell
  terraform -chdir=infra/envs/dev destroy -var image_tag=$TAG
  ```
- [ ] `51-no-load-balancers.png`: [EC2 → Load Balancers](https://us-east-1.console.aws.amazon.com/ec2/home?region=us-east-1#LoadBalancers:) is empty, or in the terminal:
  ```powershell
  aws elbv2 describe-load-balancers --query 'LoadBalancers[].LoadBalancerName'
  aws ec2 describe-nat-gateways --filter Name=state,Values=available --query 'NatGateways[].NatGatewayId'
  ```
- [ ] `52-cost-explorer.png`: Billing → Cost Explorer, daily, filtered to the project dates. This is the actual cost of the project.

---

## Generate traffic

Light, steady traffic (about one request per second for 10 minutes) so the dashboard has data. It costs nothing meaningful:

```powershell
$end = (Get-Date).AddMinutes(10)
while ((Get-Date) -lt $end) {
  curl.exe -s -o NUL "$URL/" ; curl.exe -s -o NUL "$URL/api/health" ; Start-Sleep 1
}
```

## Known findings

- **2026-10-19, image `c8b0e03`:** ECR scan reports **1 HIGH**, `CVE-2026-85091` in `zlib 1.3.2-r0`, inherited from the `node:22-alpine` base image rather than the application code. Planned fix: rebuild with patched Alpine packages and capture a clean rescan as a before/after pair.
