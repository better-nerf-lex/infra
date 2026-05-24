# Infrastructure Agent Guide

## Scope

`infra` is the Terraform source of truth for Lexai AWS deployment. It provisions/wires VPC networking, ECS services and discovery, ALB routing, CloudFront/S3 frontend delivery, RDS PostgreSQL, Cognito, IAM, ECR, Secrets Manager integration, ACM/DNS behavior, and optional OpenSearch.

When this repository is opened inside the Lexai parent workspace, also follow `../devtools/docs/agents/WORKSPACE.md`, `../devtools/docs/agents/ARCHITECTURE.md`, and `../devtools/docs/agents/DELIVERY.md`.

## Layout

| Path | Responsibility |
| --- | --- |
| `modules/*` | Reusable infrastructure building blocks and their interfaces |
| `envs/dev` | Development AWS composition; currently includes gateway, file, and subscription service wiring |
| `envs/prod` | Production composition; check parity before promoting dev features |
| `envs/local` | Local/LocalStack-oriented infrastructure composition |
| `schema` and `manual` | Supporting database/manual operational resources |

Read additional instructions in `modules/AGENTS.md` or `envs/AGENTS.md` when editing those paths.

## Infrastructure Rules

- Terraform is authoritative. Do not fix drift by manually changing AWS resources when a Terraform change is intended.
- Prefer extending a reusable module for repeated capability and composing it per environment. Keep environment-specific values and enablement in `envs`.
- Inspect every affected environment before assuming module inputs, runtime services, database setup, routing, or secrets are equivalent.
- Preserve least privilege: ECS task permissions, security groups, public ALB routes, S3 access, and secrets access must be limited to the consuming service.
- Keep application secrets out of `.tfvars`, state output, logs, and committed examples. Pass secrets through AWS Secrets Manager/task injection patterns already present.
- Be deliberate about data-bearing or public resources: RDS, S3 documents, Cognito, DNS/certificates, ALB/CloudFront routes, backups, and state backends.
- Never run `terraform apply`, state mutation, destroy, or production-affecting AWS actions unless explicitly requested and reviewed.

## Application Contract Review

- `gateway` requires its URLs, security/runtime settings, database/Cognito/AI/email configuration, and internal `FILE_SERVICE_URL`/`SUBSCRIPTION_SERVICE_URL` wiring.
- `file-service` requires a documents bucket and AWS permissions/configuration; private objects must not become public delivery assets.
- `subscription-service` requires its database/configuration, Stripe secrets and price IDs, internal access from gateway, and a tightly scoped public Stripe webhook route where configured.
- `client-front` deployment and API routing involve the frontend bucket/CloudFront and backend routing/CORS assumptions.

## Commands

Format the entire infrastructure repository after edits:

```bash
terraform fmt -recursive
terraform fmt -check -recursive
```

From each affected initialized environment directory, run:

```bash
terraform validate
terraform plan
```

Review plans for replacement, deletion, public exposure, IAM broadening, secret output, database/storage impact, routing, and environment drift before proposing application.
