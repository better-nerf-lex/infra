# S3 bucket for schema SQL files
resource "aws_s3_bucket" "schema_files" {
  bucket = "${var.environment}-${var.project_name}-schema-init"

  tags = {
    Name        = "${var.environment}-schema-init-bucket"
    Environment = var.environment
    Project     = var.project_name
  }
}

resource "aws_s3_bucket_versioning" "schema_files" {
  bucket = aws_s3_bucket.schema_files.id
  versioning_configuration {
    status = "Enabled"
  }
}

# Upload schema files to S3
resource "aws_s3_object" "init_schema" {
  bucket = aws_s3_bucket.schema_files.id
  key    = "init-schema.sql"
  source = "${path.module}/../../schema/init-schema.sql"
  etag   = filemd5("${path.module}/../../schema/init-schema.sql")

  tags = {
    Name        = "init-schema"
    Environment = var.environment
  }
}

# Security group for Lambda
resource "aws_security_group" "lambda" {
  name        = "${var.environment}-rds-init-lambda-sg"
  description = "Security group for RDS initialization Lambda"
  vpc_id      = var.vpc_id

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
    description = "Allow all outbound traffic"
  }

  tags = {
    Name        = "${var.environment}-rds-init-lambda-sg"
    Environment = var.environment
    Project     = var.project_name
  }
}

# Allow Lambda to connect to RDS
resource "aws_security_group_rule" "lambda_to_rds" {
  type                     = "ingress"
  from_port                = 5432
  to_port                  = 5432
  protocol                 = "tcp"
  security_group_id        = var.db_security_group_id
  source_security_group_id = aws_security_group.lambda.id
  description              = "Allow Lambda to connect to RDS"
}

# IAM role for Lambda
resource "aws_iam_role" "lambda_exec" {
  name = "${var.environment}-rds-init-lambda-role"

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
    Name        = "${var.environment}-rds-init-lambda-role"
    Environment = var.environment
    Project     = var.project_name
  }
}

# IAM policy for Lambda
resource "aws_iam_role_policy" "lambda_policy" {
  name = "${var.environment}-rds-init-lambda-policy"
  role = aws_iam_role.lambda_exec.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents"
        ]
        Resource = "arn:aws:logs:*:*:*"
      },
      {
        Effect = "Allow"
        Action = [
          "ec2:CreateNetworkInterface",
          "ec2:DescribeNetworkInterfaces",
          "ec2:DeleteNetworkInterface",
          "ec2:AssignPrivateIpAddresses",
          "ec2:UnassignPrivateIpAddresses"
        ]
        Resource = "*"
      },
      {
        Effect = "Allow"
        Action = [
          "secretsmanager:GetSecretValue"
        ]
        Resource = var.db_secret_arn
      },
      {
        Effect = "Allow"
        Action = [
          "s3:GetObject"
        ]
        Resource = "${aws_s3_bucket.schema_files.arn}/*"
      }
    ]
  })
}

# Package Lambda function
data "archive_file" "lambda_package" {
  type        = "zip"
  source_file = "${path.module}/lambda_init.py"
  output_path = "${path.module}/lambda_init.zip"
}

# Lambda Layer with psycopg2
# Note: You'll need to create this layer separately or use a public ARN
# For now, using a placeholder - you'll need to either:
# 1. Use a public psycopg2 layer ARN for your region
# 2. Build the layer yourself with: pip install psycopg2-binary -t python/
resource "aws_lambda_layer_version" "psycopg2" {
  filename            = "${path.module}/psycopg2-layer.zip"
  layer_name          = "${var.environment}-psycopg2"
  compatible_runtimes = ["python3.11", "python3.12"]
  description         = "psycopg2 library for PostgreSQL connections"

  # This file needs to be created - see README
  lifecycle {
    ignore_changes = [filename]
  }
}

# Lambda function
resource "aws_lambda_function" "rds_init" {
  filename         = data.archive_file.lambda_package.output_path
  function_name    = "${var.environment}-rds-schema-init"
  role             = aws_iam_role.lambda_exec.arn
  handler          = "lambda_init.lambda_handler"
  source_code_hash = data.archive_file.lambda_package.output_base64sha256
  runtime          = "python3.12"
  timeout          = 300
  memory_size      = 512

  vpc_config {
    subnet_ids         = var.private_subnet_ids
    security_group_ids = [aws_security_group.lambda.id]
  }

  environment {
    variables = {
      DB_HOST         = var.db_host
      DB_PORT         = "5432"
      DB_NAME         = var.db_name
      DB_SECRET_ARN   = var.db_secret_arn
      SCHEMA_BUCKET   = aws_s3_bucket.schema_files.id
      INIT_SCHEMA_KEY = aws_s3_object.init_schema.key
      ENVIRONMENT     = var.environment
    }
  }

  layers = [aws_lambda_layer_version.psycopg2.arn]

  depends_on = [
    aws_iam_role_policy.lambda_policy,
    aws_s3_object.init_schema,
    aws_security_group_rule.lambda_to_rds
  ]

  tags = {
    Name        = "${var.environment}-rds-schema-init"
    Environment = var.environment
    Project     = var.project_name
  }
}

# CloudWatch Log Group
resource "aws_cloudwatch_log_group" "lambda_logs" {
  name              = "/aws/lambda/${aws_lambda_function.rds_init.function_name}"
  retention_in_days = var.environment == "prod" ? 30 : 7

  tags = {
    Name        = "${var.environment}-rds-init-logs"
    Environment = var.environment
    Project     = var.project_name
  }
}

# Invoke Lambda to initialize schema
resource "null_resource" "invoke_lambda" {
  triggers = {
    schema_version      = filemd5("${path.module}/../../schema/init-schema.sql")
    lambda_function_arn = aws_lambda_function.rds_init.arn
  }

  provisioner "local-exec" {
    command = <<-EOT
      aws lambda invoke \
        --function-name ${aws_lambda_function.rds_init.function_name} \
        --payload '{}' \
        --region ${data.aws_region.current.name} \
        /tmp/lambda-response.json
      cat /tmp/lambda-response.json
    EOT
  }

  depends_on = [
    aws_lambda_function.rds_init,
    aws_s3_object.init_schema
  ]
}

data "aws_region" "current" {}
