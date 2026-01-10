variable "environment" {
  description = "Environment name (dev, prod)"
  type        = string
}

variable "project_name" {
  description = "Project name for resource tagging"
  type        = string
  default     = "lexai"
}

variable "domain_name" {
  description = "Root domain name (e.g., bntech.dev)"
  type        = string
}

variable "api_subdomain" {
  description = "API subdomain (e.g., api-test-lex.bntech.dev)"
  type        = string
}

variable "frontend_subdomain" {
  description = "Frontend subdomain (e.g., test-lex.bntech.dev)"
  type        = string
}
