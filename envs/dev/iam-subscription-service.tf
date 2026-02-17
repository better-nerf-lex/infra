# IAM policy for subscription-service
# Allows subscription service to access necessary AWS resources

# Access to Secrets Manager for database credentials and Stripe keys
resource "aws_iam_role_policy" "subscription_service_secrets" {
  name = "${var.environment}-subscription-service-secrets-policy"
  role = module.subscription_service.task_role_name

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "secretsmanager:GetSecretValue"
        ]
        Resource = [
          module.rds.db_secret_arn,
          aws_secretsmanager_secret.gateway_secrets.arn
        ]
      }
    ]
  })
}
