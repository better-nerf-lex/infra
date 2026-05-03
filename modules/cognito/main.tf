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

  # Email configuration: use Cognito's built-in sender in dev.
  email_configuration {
    email_sending_account = "COGNITO_DEFAULT"
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

  # Lambda triggers - disabled due to psycopg2 layer issues
  # Backend will create users on first API call instead
  # lambda_config {
  #   post_authentication = aws_lambda_function.post_auth.arn
  # }

  tags = {
    Environment = var.environment
    Project     = var.project_name
  }
}


resource "aws_cognito_identity_provider" "google" {
  user_pool_id  = aws_cognito_user_pool.main.id
  provider_name = "Google"
  provider_type = "Google"

  provider_details = {
    authorize_scopes              = "email profile openid"
    client_id                     = var.google_client_id
    client_secret                 = var.google_client_secret
    attributes_url                = "https://people.googleapis.com/v1/people/me?personFields="
    attributes_url_add_attributes = "true"
    authorize_url                 = "https://accounts.google.com/o/oauth2/v2/auth"
    oidc_issuer                   = "https://accounts.google.com"
    token_request_method          = "POST"
    token_url                     = "https://www.googleapis.com/oauth2/v4/token"
  }

  attribute_mapping = {
    email          = "email"
    email_verified = "email_verified"
    username       = "sub"
  }
}

# User Pool Client (for gateway app)
resource "aws_cognito_user_pool_client" "main" {
  name         = "${var.environment}-${var.project_name}-client"
  user_pool_id = aws_cognito_user_pool.main.id

  supported_identity_providers = ["COGNITO", "Google"]

  # OAuth flows
  allowed_oauth_flows_user_pool_client = true
  allowed_oauth_flows                  = ["code", "implicit"]
  allowed_oauth_scopes                 = ["email", "openid", "profile"]

  # Callback URLs (must match Amplify redirectSignIn EXACTLY, including trailing slashes)
  callback_urls = [
    "https://test-0.paragrafic.pl",
    "https://test-0.paragrafic.pl/",
    "https://paragrafic.pl",
    "https://paragrafic.pl/",
    "http://localhost:5173",
    "http://localhost:5173/",
    "http://localhost:8080",
    "http://localhost:8080/"
  ]

  logout_urls = [
    "https://test-0.paragrafic.pl",
    "https://test-0.paragrafic.pl/",
    "https://paragrafic.pl",
    "https://paragrafic.pl/",
    "http://localhost:5173",
    "http://localhost:5173/",
    "http://localhost:8080",
    "http://localhost:8080/"
  ]

  # Token validity
  access_token_validity  = 60 # minutes
  id_token_validity      = 60
  refresh_token_validity = 30 # days

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
