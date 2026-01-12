# Cognito User Pool for authentication
module "cognito" {
  source = "../../modules/cognito"

  environment  = var.environment
  project_name = var.project_name

  # SES email for verification emails (must be verified in SES first)
  ses_email_identity = var.ses_email_identity

  # Google OAuth
  google_client_id     = var.google_client_id
  google_client_secret = var.google_client_secret

  # Post-authentication Lambda configuration
  post_auth_lambda_role_arn = aws_iam_role.cognito_post_auth_lambda.arn
  db_host                   = module.rds.db_address
  db_secret_arn             = module.rds.db_secret_arn
  db_name                   = module.rds.db_name
  vpc_id                    = module.vpc.vpc_id
  private_subnet_ids        = module.vpc.private_subnet_ids
  lambda_security_group_id = module.rds_init.lambda_security_group_id
  psycopg2_layer_arn       = module.rds_init.psycopg2_layer_arn

  depends_on = [module.rds, module.rds_init, aws_iam_role.cognito_post_auth_lambda]
}

# Note: RDS access is provided by reusing the rds_init.lambda_security_group_id
# which already has ingress rules to the RDS security group
