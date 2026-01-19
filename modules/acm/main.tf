locals {
  create_api_certificate      = var.existing_api_certificate_arn == ""
  create_frontend_certificate = var.existing_frontend_certificate_arn == ""
}

data "aws_route53_zone" "main" {
  count        = var.use_route53 ? 1 : 0
  name         = var.domain_name
  private_zone = false
}

resource "aws_acm_certificate" "api" {
  count             = local.create_api_certificate ? 1 : 0
  domain_name       = var.api_subdomain
  validation_method = "DNS"

  lifecycle {
    create_before_destroy = true
  }

  tags = {
    Name        = "${var.environment}-api-cert"
    Environment = var.environment
    Project     = var.project_name
  }
}

resource "aws_route53_record" "api_cert_validation" {
  for_each = local.create_api_certificate && var.use_route53 ? {
    for dvo in aws_acm_certificate.api[0].domain_validation_options : dvo.domain_name => {
      record_name  = dvo.resource_record_name
      record_value = dvo.resource_record_value
      record_type  = dvo.resource_record_type
    }
  } : {}

  allow_overwrite = true
  name            = each.value.record_name
  records         = [each.value.record_value]
  ttl             = 60
  type            = each.value.record_type
  zone_id         = data.aws_route53_zone.main[0].zone_id
}

resource "aws_acm_certificate_validation" "api" {
  count                   = local.create_api_certificate && var.use_route53 ? 1 : 0
  certificate_arn         = aws_acm_certificate.api[0].arn
  validation_record_fqdns = [for record in aws_route53_record.api_cert_validation : record.fqdn]
}
resource "aws_acm_certificate" "frontend" {
  count    = local.create_frontend_certificate ? 1 : 0
  provider = aws.us_east_1

  domain_name       = var.frontend_subdomain
  validation_method = "DNS"

  lifecycle {
    create_before_destroy = true
  }

  tags = {
    Name        = "${var.environment}-frontend-cert"
    Environment = var.environment
    Project     = var.project_name
  }
}

resource "aws_route53_record" "frontend_cert_validation" {
  for_each = local.create_frontend_certificate && var.use_route53 ? {
    for dvo in aws_acm_certificate.frontend[0].domain_validation_options : dvo.domain_name => {
      record_name  = dvo.resource_record_name
      record_value = dvo.resource_record_value
      record_type  = dvo.resource_record_type
    }
  } : {}

  allow_overwrite = true
  name            = each.value.record_name
  records         = [each.value.record_value]
  ttl             = 60
  type            = each.value.record_type
  zone_id         = data.aws_route53_zone.main[0].zone_id
}

resource "aws_acm_certificate_validation" "frontend" {
  provider = aws.us_east_1
  count    = local.create_frontend_certificate && var.use_route53 ? 1 : 0

  certificate_arn         = aws_acm_certificate.frontend[0].arn
  validation_record_fqdns = [for record in aws_route53_record.frontend_cert_validation : record.fqdn]
}
