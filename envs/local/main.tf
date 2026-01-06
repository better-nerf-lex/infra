# =============================================================================
# Local Environment (LocalStack) - Simplified Configuration
# =============================================================================
# This configuration is narrowed down to test only the following services:
# - S3 (frontend bucket)
# - Cognito (user pool)
# - CloudFront (distribution)
# - ECR (container registry)
# - ECS (cluster only)
#
# Modules that require Route53, STS, or EC2 data sources have been removed
# to avoid LocalStack service dependency issues.
# =============================================================================

# -----------------------------------------------------------------------------
# S3 Frontend Bucket
# -----------------------------------------------------------------------------
module "s3_frontend" {
  source = "../../modules/s3-frontend"

  environment            = var.environment
  project_name           = var.project_name
  version_retention_days = 30
}

# -----------------------------------------------------------------------------
# CloudFront Distribution (simplified - no ACM certificate)
# -----------------------------------------------------------------------------
resource "aws_cloudfront_distribution" "frontend" {
  enabled             = true
  is_ipv6_enabled     = true
  comment             = "${var.environment} ${var.project_name} frontend (local)"
  default_root_object = "index.html"
  price_class         = "PriceClass_100"

  origin {
    domain_name = module.s3_frontend.bucket_regional_domain_name
    origin_id   = "S3-${module.s3_frontend.bucket_name}"

    s3_origin_config {
      origin_access_identity = module.s3_frontend.cloudfront_oai_path
    }
  }

  default_cache_behavior {
    allowed_methods  = ["GET", "HEAD", "OPTIONS"]
    cached_methods   = ["GET", "HEAD"]
    target_origin_id = "S3-${module.s3_frontend.bucket_name}"

    forwarded_values {
      query_string = false
      headers      = ["Origin", "Access-Control-Request-Headers", "Access-Control-Request-Method"]

      cookies {
        forward = "none"
      }
    }

    viewer_protocol_policy = "allow-all"
    min_ttl                = 0
    default_ttl            = 3600
    max_ttl                = 86400
    compress               = true
  }

  restrictions {
    geo_restriction {
      restriction_type = "none"
    }
  }

  # Use CloudFront default certificate for local testing (no custom domain)
  viewer_certificate {
    cloudfront_default_certificate = true
  }

  tags = {
    Name        = "${var.environment}-${var.project_name}-cdn"
    Environment = var.environment
    Project     = var.project_name
  }
}

# -----------------------------------------------------------------------------
# ECR Repository
# -----------------------------------------------------------------------------
module "ecr" {
  source = "../../modules/ecr"

  environment           = var.environment
  project_name          = var.project_name
  repository_names      = var.repository_names
  image_retention_count = var.image_retention_count
}

# -----------------------------------------------------------------------------
# ECS Cluster (cluster only, no services - they require VPC/ALB)
# -----------------------------------------------------------------------------
module "ecs_cluster" {
  source = "../../modules/ecs-cluster"

  environment               = var.environment
  project_name              = var.project_name
  enable_container_insights = var.enable_container_insights
  log_retention_days        = var.log_retention_days
}

# -----------------------------------------------------------------------------
# Cognito User Pool
# -----------------------------------------------------------------------------
resource "aws_cognito_user_pool" "main" {
  name = "${var.environment}-${var.project_name}-user-pool"

  # Password policy
  password_policy {
    minimum_length    = 8
    require_lowercase = true
    require_numbers   = true
    require_symbols   = false
    require_uppercase = true
  }

  # Account recovery
  account_recovery_setting {
    recovery_mechanism {
      name     = "verified_email"
      priority = 1
    }
  }

  # Auto-verified attributes
  auto_verified_attributes = ["email"]

  # Email configuration (use Cognito default for local testing)
  email_configuration {
    email_sending_account = "COGNITO_DEFAULT"
  }

  # Schema attributes
  schema {
    name                     = "email"
    attribute_data_type      = "String"
    required                 = true
    mutable                  = true
    developer_only_attribute = false

    string_attribute_constraints {
      min_length = 1
      max_length = 256
    }
  }

  schema {
    name                     = "name"
    attribute_data_type      = "String"
    required                 = false
    mutable                  = true
    developer_only_attribute = false

    string_attribute_constraints {
      min_length = 1
      max_length = 256
    }
  }

  tags = {
    Name        = "${var.environment}-${var.project_name}-user-pool"
    Environment = var.environment
    Project     = var.project_name
  }
}

resource "aws_cognito_user_pool_client" "main" {
  name         = "${var.environment}-${var.project_name}-client"
  user_pool_id = aws_cognito_user_pool.main.id

  # Token validity
  access_token_validity  = 1
  id_token_validity      = 1
  refresh_token_validity = 30

  token_validity_units {
    access_token  = "hours"
    id_token      = "hours"
    refresh_token = "days"
  }

  # Auth flows
  explicit_auth_flows = [
    "ALLOW_USER_PASSWORD_AUTH",
    "ALLOW_REFRESH_TOKEN_AUTH",
    "ALLOW_USER_SRP_AUTH"
  ]

  # No secret for public clients (SPAs)
  generate_secret = false

  # Prevent user existence errors
  prevent_user_existence_errors = "ENABLED"

  # Supported identity providers
  supported_identity_providers = ["COGNITO"]
}

# Optional: Cognito User Pool Domain (for hosted UI)
resource "aws_cognito_user_pool_domain" "main" {
  domain       = "${var.environment}-${var.project_name}-auth"
  user_pool_id = aws_cognito_user_pool.main.id
}
