# Digital Launch Reliability Platform

Independent Nintendo-inspired DevOps portfolio project. **Not affiliated with Nintendo.** The fictional launch content is original.

## Current scope: Phase 1 / Step 1

This starter contains a working Next.js/TypeScript application, a `/api/health` endpoint, and a multi-stage Dockerfile. **AWS resources, Terraform, CI/CD, Sentry, and Fastly are planned but not implemented in this download.**

## Prerequisites
- Node.js 22 and npm
- Docker Desktop / Docker Engine

## Run locally
```bash
npm ci
npm run dev
```
Open http://localhost:3000 and http://localhost:3000/api/health.

## Run in Docker
```bash
docker build -t digital-launch-web:local .
docker run --rm --name digital-launch-web -p 3000:3000 digital-launch-web:local
```
In a second terminal:
```bash
curl -i http://localhost:3000/api/health
```
Expected: HTTP 200 and JSON with `status: healthy`.

## Build plan
1. **Completed in source:** Next.js site, health endpoint, Dockerfile.
2. **Next:** Terraform AWS VPC (2 AZs), public ALB, private ECS tasks, ECR, CloudWatch and least-privilege IAM.
3. GitHub Actions with OIDC, tests, versioned images and safe deployment.
4. Sentry, SLO dashboards, failure injection and load tests.
5. Fastly CDN, cache invalidation and edge observability.

## Cost and security
Do not provision AWS infrastructure until you've set budget alerts and reviewed costs. An ALB, NAT gateways/VPC endpoints, ECS Fargate and data transfer can incur charges when idle. The initial HTTP ALB is for controlled development testing only; configure HTTPS and origin protection before any production-style exposure. Never commit secrets, credentials, or Terraform state.

## Success criteria
- `npm ci` and `npm run build` succeed.
- Docker image builds and serves port 3000.
- `/api/health` returns HTTP 200.
- No AWS resources are created by this starter.
