output "api_certificate_arn" {
  description = "ARN of the API ACM certificate"
  value = var.existing_api_certificate_arn != "" ? var.existing_api_certificate_arn : (
    var.use_route53 ? aws_acm_certificate_validation.api[0].certificate_arn : aws_acm_certificate.api[0].arn
  )
}

output "frontend_certificate_arn" {
  description = "ARN of the frontend ACM certificate (us-east-1)"
  value = var.existing_frontend_certificate_arn != "" ? var.existing_frontend_certificate_arn : (
    var.use_route53 ? aws_acm_certificate_validation.frontend[0].certificate_arn : aws_acm_certificate.frontend[0].arn
  )
}

output "api_domain_name" {
  description = "API domain name"
  value       = var.existing_api_certificate_arn != "" ? var.api_subdomain : aws_acm_certificate.api[0].domain_name
}

output "frontend_domain_name" {
  description = "Frontend domain name"
  value       = var.existing_frontend_certificate_arn != "" ? var.frontend_subdomain : aws_acm_certificate.frontend[0].domain_name
}

output "route53_zone_id" {
  description = "The Route53 zone ID (only available when use_route53 = true)"
  value       = var.use_route53 ? data.aws_route53_zone.main[0].zone_id : null
}

output "api_dns_validation_records" {
  description = "DNS validation records for API certificate (add these to your external DNS provider)"
  value = var.existing_api_certificate_arn != "" ? [] : [
    for dvo in aws_acm_certificate.api[0].domain_validation_options : {
      name  = dvo.resource_record_name
      type  = dvo.resource_record_type
      value = dvo.resource_record_value
    }
  ]
}

output "frontend_dns_validation_records" {
  description = "DNS validation records for frontend certificate (add these to your external DNS provider)"
  value = var.existing_frontend_certificate_arn != "" ? [] : [
    for dvo in aws_acm_certificate.frontend[0].domain_validation_options : {
      name  = dvo.resource_record_name
      type  = dvo.resource_record_type
      value = dvo.resource_record_value
    }
  ]
}
