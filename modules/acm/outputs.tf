output "api_certificate_arn" {
  description = "ARN of the API ACM certificate"
  value       = aws_acm_certificate.api.arn
}

output "frontend_certificate_arn" {
  description = "ARN of the frontend ACM certificate (us-east-1)"
  value       = aws_acm_certificate.frontend.arn
}

output "api_domain_name" {
  description = "API domain name"
  value       = aws_acm_certificate.api.domain_name
}

output "frontend_domain_name" {
  description = "Frontend domain name"
  value       = aws_acm_certificate.frontend.domain_name
}

output "route53_zone_id" {
  description = "The Route53 zone ID"
  value       = data.aws_route53_zone.main.zone_id
}
