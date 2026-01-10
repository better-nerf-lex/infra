variable "environment" {
  description = "Environment name (dev, prod)"
  type        = string
}

variable "project_name" {
  description = "Project name for resource tagging"
  type        = string
  default     = "lexai"
}

variable "version_retention_days" {
  description = "Number of days to retain old S3 object versions"
  type        = number
  default     = 30
}
