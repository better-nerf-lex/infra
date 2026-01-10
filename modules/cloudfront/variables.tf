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
  description = "Domain name for CloudFront distribution"
  type        = string
}

variable "bucket_name" {
  description = "S3 bucket name"
  type        = string
}

variable "bucket_regional_domain_name" {
  description = "S3 bucket regional domain name"
  type        = string
}

variable "cloudfront_oai_path" {
  description = "CloudFront OAI path"
  type        = string
}

variable "certificate_arn" {
  description = "ACM certificate ARN (must be in us-east-1, leave empty to use CloudFront default certificate)"
  type        = string
  default     = ""
}

variable "price_class" {
  description = "CloudFront price class"
  type        = string
  default     = "PriceClass_100"
}

variable "alb_dns_name" {
  description = "ALB DNS name for API origin"
  type        = string
  default     = ""
}
