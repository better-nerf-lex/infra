# =============================================================================
# Local Environment Variables (Simplified for LocalStack)
# =============================================================================

variable "environment" {
  description = "Environment name"
  type        = string
  default     = "local"
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

# -----------------------------------------------------------------------------
# ECR Variables
# -----------------------------------------------------------------------------
variable "repository_names" {
  description = "List of ECR repository names"
  type        = list(string)
  default     = ["gateway"]
}

variable "image_retention_count" {
  description = "Number of images to retain in ECR"
  type        = number
  default     = 10
}

# -----------------------------------------------------------------------------
# ECS Variables
# -----------------------------------------------------------------------------
variable "enable_container_insights" {
  description = "Enable CloudWatch Container Insights"
  type        = bool
  default     = false
}

variable "log_retention_days" {
  description = "CloudWatch log retention in days"
  type        = number
  default     = 7
}
