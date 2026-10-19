# Digital Launch Reliability Platform

[![CI](https://github.com/gkoufie1/digital-launch-reliability-platform/actions/workflows/ci.yml/badge.svg)](https://github.com/gkoufie1/digital-launch-reliability-platform/actions/workflows/ci.yml)

Independent Nintendo-inspired DevOps portfolio project. **Not affiliated with Nintendo.** The fictional launch content is original.

## Current scope: Phase 1 / Step 1

This starter contains a working Next.js/TypeScript application, a `/api/health` endpoint, a multi-stage Dockerfile, and a GitHub Actions CI pipeline. **AWS resources, Terraform, continuous deployment, Sentry, and Fastly are planned but not implemented yet.**

## Prerequisites
- Node.js 22.13+ and npm (see `.nvmrc`)
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

## Continuous integration
Every push to `main` and every pull request runs [`.github/workflows/ci.yml`](.github/workflows/ci.yml):

1. **Verify:** `npm ci`, lint, typecheck, production build, and `npm audit --omit=dev --audit-level=high`.
2. **Container:** builds the Docker image, starts it, and smoke-tests `/api/health` (HTTP 200, `status: healthy`, `Cache-Control: no-store`), the home page, and that the container runs as the non-root `node` user.

Actions are pinned to commit SHAs, the workflow token is read-only, and Dependabot keeps npm packages, actions, and the Docker base image up to date. CI needs no cloud credentials; AWS deployment via OIDC is added after the Terraform step.

Run the same checks locally:
```bash
npm ci && npm run lint && npm run typecheck && npm run build
```

## Build plan
1. **Completed:** Next.js site, health endpoint, Dockerfile, CI pipeline.
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
