# Post-authentication Lambda function
resource "aws_lambda_function" "post_auth" {
  filename      = "${path.module}/lambda/post_auth.zip"
  function_name = "${var.environment}-${var.project_name}-cognito-post-auth"
  role          = var.post_auth_lambda_role_arn
  handler       = "post_auth.handler"
  runtime       = "python3.11"
  timeout       = 30

  source_code_hash = filebase64sha256("${path.module}/lambda/post_auth.zip")

  vpc_config {
    subnet_ids         = var.private_subnet_ids
    security_group_ids = [var.lambda_security_group_id]
  }

  environment {
    variables = {
      DB_HOST       = var.db_host
      DB_PORT       = "5432"
      DB_NAME       = var.db_name
      DB_SECRET_ARN = var.db_secret_arn
    }
  }

  layers = [aws_lambda_layer_version.psycopg2.arn]

  tags = {
    Environment = var.environment
    Project     = var.project_name
  }
}

# Psycopg2 layer for database connectivity
resource "aws_lambda_layer_version" "psycopg2" {
  filename   = "${path.module}/lambda/psycopg2-layer.zip"
  layer_name = "${var.environment}-${var.project_name}-psycopg2"

  compatible_runtimes = ["python3.11"]

  source_code_hash = filebase64sha256("${path.module}/lambda/psycopg2-layer.zip")
}

# Permission for Cognito to invoke Lambda
resource "aws_lambda_permission" "cognito_trigger" {
  statement_id  = "AllowCognitoInvoke"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.post_auth.function_name
  principal     = "cognito-idp.amazonaws.com"
  source_arn    = aws_cognito_user_pool.main.arn
}

# Build script for Lambda zip
resource "null_resource" "build_lambda" {
  triggers = {
    code_hash = filemd5("${path.module}/lambda/post_auth.py")
  }

  provisioner "local-exec" {
    command = "cd ${path.module}/lambda && zip -j post_auth.zip post_auth.py"
  }
}
