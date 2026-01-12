variable "project_name" {
  description = "Project name for resource naming"
  type        = string
}

variable "environment" {
  description = "Environment name (dev, prod)"
  type        = string
}

variable "ses_email_identity" {
  description = "SES verified email identity for sending emails"
  type        = string
}

variable "post_auth_lambda_role_arn" {
  description = "IAM role ARN for post-authentication Lambda function"
  type        = string
}

variable "db_host" {
  description = "Database host for post-auth Lambda"
  type        = string
}

variable "db_secret_arn" {
  description = "ARN of Secrets Manager secret containing DB credentials"
  type        = string
}

variable "db_name" {
  description = "Database name"
  type        = string
}

variable "vpc_id" {
  description = "VPC ID for Lambda"
  type        = string
}

variable "private_subnet_ids" {
  description = "Private subnet IDs for Lambda"
  type        = list(string)
}

variable "lambda_security_group_id" {
  description = "Security group ID for Lambda"
  type        = string
}


variable "google_client_id" {
  description = "Google OAuth Client ID"
  type        = string
  default     = ""
}

variable "psycopg2_layer_arn" {
  description = "ARN of the psycopg2 Lambda layer"
  type        = string
}

variable "google_client_secret" {
  description = "Google OAuth Client Secret"
  type        = string
  sensitive   = true
  default     = ""
}
