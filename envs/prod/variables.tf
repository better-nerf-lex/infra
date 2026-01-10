variable "environment" {
  description = "Environment name"
  type        = string
  default     = "prod"
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
  default     = null
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
  default     = ["gateway", "payments"]
}

variable "image_retention_count" {
  description = "Number of images to retain in ECR"
  type        = number
  default     = 20
}

variable "enable_container_insights" {
  description = "Enable CloudWatch Container Insights"
  type        = bool
  default     = true
}

variable "log_retention_days" {
  description = "CloudWatch log retention in days"
  type        = number
  default     = 30
}

variable "db_instance_class" {
  description = "RDS instance class"
  type        = string
  default     = "db.t4g.small"
}

variable "db_allocated_storage" {
  description = "RDS allocated storage in GB"
  type        = number
  default     = 50
}

variable "db_max_allocated_storage" {
  description = "RDS max allocated storage in GB"
  type        = number
  default     = 200
}

variable "db_multi_az" {
  description = "Enable multi-AZ for RDS"
  type        = bool
  default     = true
}

variable "db_backup_retention_period" {
  description = "RDS backup retention period in days"
  type        = number
  default     = 30
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
  default     = 512
}

variable "gateway_memory" {
  description = "Gateway service memory in MB"
  type        = number
  default     = 1024
}

variable "gateway_desired_count" {
  description = "Gateway service desired task count"
  type        = number
  default     = 2
}

variable "gateway_min_capacity" {
  description = "Gateway service minimum task count"
  type        = number
  default     = 2
}

variable "gateway_max_capacity" {
  description = "Gateway service maximum task count"
  type        = number
  default     = 6
}

variable "enable_payments_service" {
  description = "Enable payments service"
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
