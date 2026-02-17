variable "environment" {
  description = "Environment name"
  type        = string
  default     = "dev"
}

variable "project_name" {
  description = "Project name"
  type        = string
  default     = "paragrafic"
}

variable "aws_region" {
  description = "AWS region"
  type        = string
  default     = "eu-north-1"
}

variable "aws_profile" {
  description = "AWS profile to use for authentication"
  type        = string
  default     = "terraform"
}

variable "vpc_cidr" {
  description = "VPC CIDR block"
  type        = string
  default     = "10.0.0.0/16"
}

variable "az_count" {
  description = "Number of availability zones"
  type        = number
  default     = 2
}

variable "domain_name" {
  description = "Root domain name"
  type        = string
  default     = "paragrafic.pl"
}

variable "frontend_domain" {
  description = "Frontend domain"
  type        = string
  default     = "test-0.paragrafic.pl"
}

variable "api_domain" {
  description = "API domain"
  type        = string
  default     = "test-0.paragrafic.pl"
}

variable "repository_names" {
  description = "List of ECR repository names"
  type        = list(string)
  default     = ["gateway", "file-service", "paragrafic-front"]
}

variable "image_retention_count" {
  description = "Number of images to retain in ECR"
  type        = number
  default     = 10
}

variable "enable_container_insights" {
  description = "Enable CloudWatch Container Insights"
  type        = bool
  default     = true
}

variable "log_retention_days" {
  description = "CloudWatch log retention in days"
  type        = number
  default     = 7
}

variable "db_instance_class" {
  description = "RDS instance class"
  type        = string
  default     = "db.t4g.micro"
}

variable "db_allocated_storage" {
  description = "RDS allocated storage in GB"
  type        = number
  default     = 20
}

variable "db_max_allocated_storage" {
  description = "RDS max allocated storage in GB"
  type        = number
  default     = 50
}

variable "db_multi_az" {
  description = "Enable multi-AZ for RDS"
  type        = bool
  default     = false
}

variable "db_backup_retention_period" {
  description = "RDS backup retention period in days"
  type        = number
  default     = 7
}

variable "github_org" {
  description = "GitHub organization or username"
  type        = string
}

variable "github_repositories" {
  description = "List of GitHub repository names allowed to assume the IAM role"
  type        = list(string)
}

variable "gateway_image_uri" {
  description = "Gateway service Docker image URI"
  type        = string
}

variable "gateway_cpu" {
  description = "Gateway service CPU units"
  type        = number
  default     = 256
}

variable "gateway_memory" {
  description = "Gateway service memory in MB"
  type        = number
  default     = 512
}

variable "gateway_desired_count" {
  description = "Gateway service desired task count"
  type        = number
  default     = 1
}

variable "gateway_min_capacity" {
  description = "Gateway service minimum task count"
  type        = number
  default     = 1
}

variable "gateway_max_capacity" {
  description = "Gateway service maximum task count"
  type        = number
  default     = 1
}

variable "enable_payments_service" {
  description = "Enable payments service"
  type        = bool
  default     = false
}

variable "enable_elasticsearch" {
  description = "Enable Elasticsearch (OpenSearch)"
  type        = bool
  default     = false
}

variable "use_route53" {
  description = "Whether to use Route 53 for DNS management (set to false if domain is managed externally)"
  type        = bool
  default     = false
}

variable "enable_ssl_certificates" {
  description = "Whether to enable SSL/TLS certificates for ALB and CloudFront (set to false on first apply if using external DNS, then true after DNS validation)"
  type        = bool
  default     = false
}

variable "existing_api_certificate_arn" {
  description = "ARN of an existing ACM certificate for the API (ALB). If provided, no new certificate will be created. Must be in the same region as the ALB."
  type        = string
  default     = ""
}

variable "existing_frontend_certificate_arn" {
  description = "ARN of an existing ACM certificate for the frontend (CloudFront). If provided, no new certificate will be created. Must be in us-east-1."
  type        = string
  default     = ""
}

variable "payments_image_uri" {
  description = "Payments service Docker image URI"
  type        = string
  default     = ""
}

variable "payments_cpu" {
  description = "Payments service CPU units"
  type        = number
  default     = 256
}

variable "payments_memory" {
  description = "Payments service memory in MB"
  type        = number
  default     = 512
}

variable "payments_desired_count" {
  description = "Payments service desired task count"
  type        = number
  default     = 1
}

variable "payments_min_capacity" {
  description = "Payments service minimum task count"
  type        = number
  default     = 1
}

variable "payments_max_capacity" {
  description = "Payments service maximum task count"
  type        = number
  default     = 3
}

variable "file_service_image_uri" {
  description = "File service Docker image URI"
  type        = string
  default     = ""
}

variable "file_service_cpu" {
  description = "File service CPU units"
  type        = number
  default     = 256
}

variable "file_service_memory" {
  description = "File service memory in MB"
  type        = number
  default     = 512
}

variable "file_service_desired_count" {
  description = "File service desired task count"
  type        = number
  default     = 1
}

variable "file_service_min_capacity" {
  description = "File service minimum task count"
  type        = number
  default     = 1
}

variable "file_service_max_capacity" {
  description = "File service maximum task count"
  type        = number
  default     = 3
}


variable "anthropic_api_key" {
  description = "Anthropic API Key"
  type        = string
  sensitive   = true
}

variable "jwt_secret" {
  description = "JWT Secret Key"
  type        = string
  sensitive   = true
}

variable "google_client_id" {
  description = "Google OAuth Client ID"
  type        = string
  sensitive   = true
}

variable "google_client_secret" {
  description = "Google OAuth Client Secret"
  type        = string
  sensitive   = true
}

variable "postmark_api_token" {
  description = "Postmark API token for sending emails"
  type        = string
  sensitive   = true
}

variable "email_from" {
  description = "From email address for sending emails"
  type        = string
  default     = "noreply@paragrafic.pl"
}

variable "email_enabled" {
  description = "Enable email sending functionality"
  type        = string
  default     = "true"
}
