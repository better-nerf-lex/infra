variable "environment" {
  description = "Environment name (dev, prod)"
  type        = string
}

variable "project_name" {
  description = "Project name for resource tagging"
  type        = string
  default     = "paragrafic"
}

variable "repository_names" {
  description = "List of repository names to create"
  type        = list(string)
  default     = ["gateway", "payments"]
}

variable "image_retention_count" {
  description = "Number of images to retain in ECR"
  type        = number
  default     = 10
}
