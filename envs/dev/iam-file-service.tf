# IAM policy for file-service to access S3 documents bucket
resource "aws_iam_role_policy" "file_service_s3" {
  name = "${var.environment}-file-service-s3-policy"
  role = module.file_service.task_role_name

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "s3:PutObject",
          "s3:GetObject",
          "s3:DeleteObject",
          "s3:ListBucket"
        ]
        Resource = [
          aws_s3_bucket.documents.arn,
          "${aws_s3_bucket.documents.arn}/*"
        ]
      }
    ]
  })
}
