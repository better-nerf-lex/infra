data "aws_region" "current" {}

resource "aws_cognito_user_pool" "main" {
  name = "${var.environment}-${var.project_name}-users"

  # Email as username
  username_attributes      = ["email"]
  auto_verified_attributes = ["email"]

  # Password policy
  password_policy {
    minimum_length                   = 8
    require_lowercase                = true
    require_uppercase                = true
    require_numbers                  = true
    require_symbols                  = true
    temporary_password_validity_days = 7
  }

  # Email configuration (SES)
  email_configuration {
    email_sending_account  = "DEVELOPER"
    source_arn            = "arn:aws:ses:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:identity/${var.ses_email_identity}"
    from_email_address    = var.ses_email_identity
    reply_to_email_address = var.ses_email_identity
  }

  # MFA configuration
  mfa_configuration = "OPTIONAL"

  software_token_mfa_configuration {
    enabled = true
  }

  # Account recovery
  account_recovery_setting {
    recovery_mechanism {
      name     = "verified_email"
      priority = 1
    }
  }

  # User attribute schema
  schema {
    name                = "email"
    attribute_data_type = "String"
    required            = true
    mutable             = true

    string_attribute_constraints {
      min_length = 1
      max_length = 256
    }
  }

  # Lambda triggers
  lambda_config {
    post_authentication = aws_lambda_function.post_auth.arn
  }

  tags = {
    Environment = var.environment
    Project     = var.project_name
  }
}

# User Pool Client (for gateway app)
resource "aws_cognito_user_pool_client" "main" {
  name         = "${var.environment}-${var.project_name}-client"
  user_pool_id = aws_cognito_user_pool.main.id

  # OAuth flows
  allowed_oauth_flows_user_pool_client = true
  allowed_oauth_flows                  = ["code", "implicit"]
  allowed_oauth_scopes                 = ["email", "openid", "profile"]

  # Callback URLs (update with your frontend URL)
  callback_urls = [
    "https://test-0.paragrafic.pl",
    "https://paragrafic.pl",
    "http://localhost:8080"
  ]

  logout_urls = [
    "https://test-0.paragrafic.pl",
    "https://paragrafic.pl",
    "http://localhost:8080"
  ]

  # Token validity
  access_token_validity  = 60  # minutes
  id_token_validity      = 60
  refresh_token_validity = 30  # days

  token_validity_units {
    access_token  = "minutes"
    id_token      = "minutes"
    refresh_token = "days"
  }

  # Prevent secret generation (public client for SPA)
  generate_secret = false

  # Auth flows
  explicit_auth_flows = [
    "ALLOW_USER_SRP_AUTH",
    "ALLOW_REFRESH_TOKEN_AUTH",
    "ALLOW_USER_PASSWORD_AUTH"
  ]

  # Prevent user existence errors
  prevent_user_existence_errors = "ENABLED"
}

# User Pool Domain (for hosted UI)
resource "aws_cognito_user_pool_domain" "main" {
  domain       = "${var.environment}-${var.project_name}-auth"
  user_pool_id = aws_cognito_user_pool.main.id
}

data "aws_caller_identity" "current" {}
