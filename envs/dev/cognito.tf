# Cognito User Pool for authentication
module "cognito" {
  source = "../../modules/cognito"

  environment  = var.environment
  project_name = var.project_name

  # SES email for verification emails (must be verified in SES first)
  ses_email_identity = var.ses_email_identity

  # Post-authentication Lambda configuration
  post_auth_lambda_role_arn = aws_iam_role.cognito_post_auth_lambda.arn
  db_host                   = module.rds.db_address
  db_secret_arn             = module.rds.db_secret_arn
  db_name                   = module.rds.db_name
  vpc_id                    = module.vpc.vpc_id
  private_subnet_ids        = module.vpc.private_subnet_ids
  lambda_security_group_id  = module.rds_init.lambda_security_group_id

  depends_on = [module.rds, module.rds_init, aws_iam_role.cognito_post_auth_lambda]
}

# Allow post-auth Lambda to access RDS
resource "aws_security_group_rule" "rds_ingress_cognito_lambda" {
  type                     = "ingress"
  from_port                = 5432
  to_port                  = 5432
  protocol                 = "tcp"
  security_group_id        = module.rds.db_security_group_id
  source_security_group_id = module.rds_init.lambda_security_group_id
  description              = "Allow PostgreSQL from Cognito post-auth Lambda"
}
