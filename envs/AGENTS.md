# Terraform Environment Composition

## Scope

Files under `envs` instantiate shared modules and add environment-specific resources, routes, permissions, configuration, and secret injection.

## Rules

- Compare `dev`, `prod`, and `local` before changing a service or module interface. Implement only intentional environment differences and identify missing parity clearly.
- Keep runtime environment variables non-secret and map secrets through Secrets Manager or existing protected mechanisms.
- Validate service dependencies together: discovery URLs, target groups and health paths, security-group ingress, IAM permissions, database provisioning, and webhook exposure.
- Do not copy a dev-only convenience into production without reviewing security, persistence, availability, observability, and cost consequences.
- Keep environment plans reviewable; avoid unrelated formatting or refactors mixed into functional changes.

Run `terraform fmt` and `terraform validate` for every affected environment; obtain and inspect a plan before any apply.
