# Terraform Module Development

## Scope

Files under `modules` define reusable AWS infrastructure contracts consumed by environment compositions.

## Rules

- Keep modules focused around one deployable capability and expose typed, documented variables and useful non-secret outputs.
- Before changing a variable, output, default, resource identity, or lifecycle behavior, search every environment consumer and update or migrate it deliberately.
- Avoid hidden environment assumptions inside reusable modules; pass required variation as inputs with secure defaults.
- Review resource replacement and data-loss impact carefully for storage, databases, identity, network boundaries, certificates, service discovery, and public endpoints.
- Keep IAM and security-group grants narrowly scoped and explain any new public ingress through the consuming environment contract.

Run recursive formatting, validate affected environment consumers, and inspect plans resulting from module changes.
