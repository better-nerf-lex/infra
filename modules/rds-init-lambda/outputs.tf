output "lambda_function_arn" {
  description = "ARN of the Lambda function"
  value       = aws_lambda_function.rds_init.arn
}

output "lambda_execution_role_arn" {
  description = "ARN of the Lambda execution role"
  value       = aws_iam_role.lambda_exec.arn
}

output "initialization_status" {
  description = "Status of schema initialization"
  value       = "Schema initialization Lambda deployed"
}

output "lambda_security_group_id" {
  description = "Security group ID for Lambda function"
  value       = aws_security_group.lambda.id
}

output "psycopg2_layer_arn" {
  description = "ARN of the psycopg2 Lambda layer"
  value       = aws_lambda_layer_version.psycopg2.arn
}
