# GitHub Secrets Configuration Guide

This document outlines the required GitHub secrets for the infrastructure CI/CD workflows.

## Required Secrets

Navigate to your GitHub repository → **Settings** → **Secrets and variables** → **Actions** → **New repository secret**

### AWS Authentication

| Secret Name | Description | How to Get |
|------------|-------------|------------|
| `AWS_ACCESS_KEY_ID` | AWS access key (fallback auth) | AWS IAM Console |
| `AWS_SECRET_ACCESS_KEY` | AWS secret key (fallback auth) | AWS IAM Console |
| `AWS_REGION` | AWS region | `eu-north-1` |
| `AWS_ROLE_ARN_DEV` | GitHub Actions role ARN for dev | Run: `cd envs/dev && terraform output github_actions_role_arn` |

### Environment Variables (non-secret)

| Variable Name | Description | Value |
|------------|-------------|--------|
| `AWS_ACTIONS_ROLE_ARN` | GitHub Actions role ARN | Same as `AWS_ROLE_ARN_DEV` |

### Terraform Variables (Required)

| Secret Name | Description | Source |
|------------|-------------|--------|
| `TF_VAR_ANTHROPIC_API_KEY` | Anthropic API key for AI services | [Anthropic Console](https://console.anthropic.com/) |
| `TF_VAR_JWT_SECRET` | JWT secret for authentication | Generate: `openssl rand -base64 32` |
| `TF_VAR_GOOGLE_CLIENT_ID` | Google OAuth client ID | [Google Cloud Console](https://console.cloud.google.com/) |
| `TF_VAR_GOOGLE_CLIENT_SECRET` | Google OAuth client secret | [Google Cloud Console](https://console.cloud.google.com/) |
| `TF_VAR_POSTMARK_API_KEY` | Postmark email service API key | [Postmark Account](https://account.postmarkapp.com/) |
| `TF_VAR_STRIPE_API_KEY` | Stripe API key for payments | [Stripe Dashboard](https://dashboard.stripe.com/) |
| `TF_VAR_STRIPE_WEBHOOK_SECRET` | Stripe webhook signing secret | [Stripe Webhooks](https://dashboard.stripe.com/webhooks) |

### Discord Merge Notifications

| Secret Name | Description | Source |
|------------|-------------|--------|
| `DISCORD_WEBHOOK_URL` | Discord incoming webhook used by merge notification workflows in all repos | Discord channel settings -> Integrations -> Webhooks |

For private repositories on GitHub Free organizations, add `DISCORD_WEBHOOK_URL` as a repository secret in each repo instead of an organization secret:

- `better-nerf-lex/gateway`
- `better-nerf-lex/lexai-front`
- `better-nerf-lex/subscription-service`
- `better-nerf-lex/file-service`
- `better-nerf-lex/infra`

## GitHub Environment Protection (Production)

For the production workflow to require manual approval:

1. Navigate to **Settings** → **Environments** → **New environment**
2. Name: `production`
3. Enable **Required reviewers** and add yourself or team members
4. Save protection rules

This ensures production deployments wait for manual approval before applying Terraform changes.

## Workflow Triggers

- **Dev**: Automatically deploys on push to `dev` branch
- **Prod**: Automatically deploys on push to `main` branch, requires manual approval

Both workflows can also be triggered manually via **Actions** → **Workflow** → **Run workflow**

## Local Development

For local `terraform apply`, use the committed `dev.tfvars` file which includes `aws_profile = "terraform"`:

```bash
cd envs/dev
terraform init
terraform plan -var-file=dev.tfvars -var="anthropic_api_key=..." -var="jwt_secret=..." ...
terraform apply -var-file=dev.tfvars -var="anthropic_api_key=..." -var="jwt_secret=..." ...
```

Or create a local `terraform.tfvars` (gitignored) with all values including secrets for convenience.
