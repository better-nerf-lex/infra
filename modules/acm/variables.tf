variable "environment" {
  description = "Environment name (dev, prod)"
  type        = string
}

variable "project_name" {
  description = "Project name for resource tagging"
  type        = string
  default     = "paragrafic"
}

variable "domain_name" {
  description = "Root domain name (e.g., paragrafic.pl)"
  type        = string
}

variable "api_subdomain" {
  description = "API subdomain (e.g., api-test-0.paragrafic.pl)"
  type        = string
}

variable "frontend_subdomain" {
  description = "Frontend subdomain (e.g., test-0.paragrafic.pl)"
  type        = string
}

variable "use_route53" {
  description = "Whether to use Route 53 for DNS management and automatic certificate validation"
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
