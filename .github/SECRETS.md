# GitHub Secrets Configuration Guide

This document outlines the required GitHub secrets for the infrastructure CI/CD workflows.

## Required Secrets

Navigate to your GitHub repository → **Settings** → **Secrets and variables** → **Actions** → **New repository secret**

### AWS Authentication

| Secret Name | Description | How to Get |
|------------|-------------|------------|
| `AWS_ROLE_ARN_DEV` | GitHub Actions role ARN for dev environment | Run: `cd infra/envs/dev && terraform output github_actions_role_arn` |
| `AWS_ROLE_ARN_PROD` | GitHub Actions role ARN for prod environment | Run: `cd infra/envs/prod && terraform output github_actions_role_arn` |

### Terraform Variables

| Secret Name | Description | Source |
|------------|-------------|--------|
| `TF_VAR_ANTHROPIC_API_KEY` | Anthropic API key for AI services | [Anthropic Console](https://console.anthropic.com/) |
| `TF_VAR_JWT_SECRET` | JWT secret for authentication | Generate: `openssl rand -base64 32` |
| `TF_VAR_GOOGLE_CLIENT_ID` | Google OAuth client ID | [Google Cloud Console](https://console.cloud.google.com/) |
| `TF_VAR_GOOGLE_CLIENT_SECRET` | Google OAuth client secret | [Google Cloud Console](https://console.cloud.google.com/) |
| `TF_VAR_POSTMARK_API_KEY` | Postmark email service API key | [Postmark Account](https://account.postmarkapp.com/) |

## GitHub Environment Protection (Production)

For the production workflow to require manual approval:

1. Navigate to **Settings** → **Environments** → **New environment**
2. Name: `production`
3. Enable **Required reviewers** and add yourself or team members
4. Save protection rules

This ensures production deployments wait for manual approval before applying Terraform changes.

## Workflow Triggers

- **Dev**: Automatically deploys on merge to `develop` branch (when `infra/**` files change)
- **Prod**: Automatically deploys on merge to `main` branch (when `infra/**` files change), requires manual approval

Both workflows can also be triggered manually via **Actions** → **Workflow** → **Run workflow**
