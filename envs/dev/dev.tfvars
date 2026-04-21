# Non-sensitive configuration for dev environment
# Sensitive values (API keys, secrets) are provided via GitHub Secrets as TF_VAR_ environment variables

# Local AWS authentication (set for local terraform apply, ignored in CI/CD)
aws_profile = "terraform"

# GitHub configuration
github_org          = "better-nerf-lex"
github_repositories = ["gateway", "file-service", "subscription-service", "paragrafic-front", "infra"]

# Service Images
gateway_image_uri              = "579540613167.dkr.ecr.eu-north-1.amazonaws.com/paragrafic/gateway:latest"
file_service_image_uri         = "579540613167.dkr.ecr.eu-north-1.amazonaws.com/paragrafic/file-service:latest"
subscription_service_image_uri = "579540613167.dkr.ecr.eu-north-1.amazonaws.com/paragrafic/subscription-service:latest"
payments_image_uri             = "579540613167.dkr.ecr.eu-north-1.amazonaws.com/paragrafic/payments:latest"

# Domain configuration
domain_name     = "paragrafic.pl"
frontend_domain = "test-0.paragrafic.pl"
api_domain      = "test-0.paragrafic.pl"

# DNS Configuration
use_route53 = false

# SSL/TLS Certificates
enable_ssl_certificates          = true
existing_frontend_certificate_arn = "arn:aws:acm:us-east-1:579540613167:certificate/2c36aa0d-e22c-42c8-82bc-2a55d51972d6"
existing_api_certificate_arn      = "arn:aws:acm:eu-north-1:579540613167:certificate/28ee2755-06a2-4353-a9b2-9037bc760990"

# OpenSearch
enable_elasticsearch = true
