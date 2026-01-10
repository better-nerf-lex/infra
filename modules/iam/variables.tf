variable "environment" {
  description = "Environment name (dev, prod)"
  type        = string
}

variable "project_name" {
  description = "Project name for resource tagging"
  type        = string
  default     = "lexai"
}

variable "github_org" {
  description = "GitHub organization or username"
  type        = string
}

variable "github_repositories" {
  description = "List of GitHub repository names allowed to assume the IAM role"
  type        = list(string)
}
