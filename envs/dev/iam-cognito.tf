# IAM role for Cognito post-authentication Lambda
resource "aws_iam_role" "cognito_post_auth_lambda" {
  name = "${var.environment}-${var.project_name}-cognito-post-auth-lambda"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "lambda.amazonaws.com"
        }
      }
    ]
  })

  tags = {
    Environment = var.environment
    Project     = var.project_name
  }
}

# Attach basic execution policy
resource "aws_iam_role_policy_attachment" "cognito_post_auth_lambda_basic" {
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
  role       = aws_iam_role.cognito_post_auth_lambda.name
}

# Attach VPC execution policy
resource "aws_iam_role_policy_attachment" "cognito_post_auth_lambda_vpc" {
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaVPCAccessExecutionRole"
  role       = aws_iam_role.cognito_post_auth_lambda.name
}

# Policy for Secrets Manager access
resource "aws_iam_role_policy" "cognito_post_auth_lambda_secrets" {
  name = "${var.environment}-${var.project_name}-cognito-post-auth-secrets"
  role = aws_iam_role.cognito_post_auth_lambda.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "secretsmanager:GetSecretValue"
        ]
        Resource = module.rds.db_secret_arn
      }
    ]
  })
}
