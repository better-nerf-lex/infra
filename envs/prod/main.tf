module "vpc" {
  source = "../../modules/vpc"

  environment  = var.environment
  project_name = var.project_name
  vpc_cidr     = var.vpc_cidr
  az_count     = var.az_count
}

module "ecr" {
  source = "../../modules/ecr"

  environment           = var.environment
  project_name          = var.project_name
  repository_names      = var.repository_names
  image_retention_count = var.image_retention_count
}

module "ecs_cluster" {
  source = "../../modules/ecs-cluster"

  environment               = var.environment
  project_name              = var.project_name
  enable_container_insights = var.enable_container_insights
  log_retention_days        = var.log_retention_days
}

module "s3_frontend" {
  source = "../../modules/s3-frontend"

  environment            = var.environment
  project_name           = var.project_name
  version_retention_days = 30
}

module "cloudfront" {
  source = "../../modules/cloudfront"

  environment                 = var.environment
  project_name                = var.project_name
  domain_name                 = var.frontend_domain
  bucket_name                 = module.s3_frontend.bucket_name
  bucket_regional_domain_name = module.s3_frontend.bucket_regional_domain_name
  cloudfront_oai_path         = module.s3_frontend.cloudfront_oai_path
  certificate_arn             = module.acm.frontend_certificate_arn
  price_class                 = "PriceClass_100"

  depends_on = [module.s3_frontend, module.acm]
}

module "acm" {
  source = "../../modules/acm"

  providers = {
    aws.us_east_1 = aws.us_east_1
  }

  environment        = var.environment
  project_name       = var.project_name
  domain_name        = var.domain_name
  api_subdomain      = var.api_domain
  frontend_subdomain = var.frontend_domain
}

# Route53 record for API (points to ALB)
resource "aws_route53_record" "api" {
  zone_id = module.acm.route53_zone_id
  name    = var.api_domain
  type    = "A"

  alias {
    name                   = module.alb.alb_dns_name
    zone_id                = module.alb.alb_zone_id
    evaluate_target_health = true
  }
}

# Route53 record for Frontend (points to CloudFront)
resource "aws_route53_record" "frontend" {
  zone_id = module.acm.route53_zone_id
  name    = var.frontend_domain
  type    = "A"

  alias {
    name                   = module.cloudfront.distribution_domain_name
    zone_id                = module.cloudfront.distribution_hosted_zone_id
    evaluate_target_health = false
  }
}

module "alb" {
  source = "../../modules/alb"

  environment               = var.environment
  project_name              = var.project_name
  vpc_id                    = module.vpc.vpc_id
  public_subnet_ids         = module.vpc.public_subnet_ids
  certificate_arn           = module.acm.api_certificate_arn
  enable_payments_service   = var.enable_payments_service

  depends_on = [module.acm]
}

module "rds" {
  source = "../../modules/rds"

  environment             = var.environment
  project_name            = var.project_name
  vpc_id                  = module.vpc.vpc_id
  private_subnet_ids      = module.vpc.private_subnet_ids
  instance_class          = var.db_instance_class
  allocated_storage       = var.db_allocated_storage
  max_allocated_storage   = var.db_max_allocated_storage
  multi_az                = var.db_multi_az
  backup_retention_period = var.db_backup_retention_period

  depends_on = [module.vpc]
}

resource "aws_security_group_rule" "rds_ingress_gateway" {
  type                     = "ingress"
  from_port                = 5432
  to_port                  = 5432
  protocol                 = "tcp"
  security_group_id        = module.rds.db_security_group_id
  source_security_group_id = module.gateway_service.security_group_id
  description              = "Allow PostgreSQL from gateway service"
}

resource "aws_security_group_rule" "rds_ingress_payments" {
  count                    = var.enable_payments_service ? 1 : 0
  type                     = "ingress"
  from_port                = 5432
  to_port                  = 5432
  protocol                 = "tcp"
  security_group_id        = module.rds.db_security_group_id
  source_security_group_id = module.payments_service[0].security_group_id
  description              = "Allow PostgreSQL from payments service"
}

module "iam" {
  source = "../../modules/iam"

  environment  = var.environment
  project_name = var.project_name
  github_org   = var.github_org
  github_repo  = var.github_repo
}

module "gateway_service" {
  source = "../../modules/ecs-service"

  environment           = var.environment
  project_name          = var.project_name
  service_name          = "gateway"
  vpc_id                = module.vpc.vpc_id
  private_subnet_ids    = module.vpc.private_subnet_ids
  cluster_id            = module.ecs_cluster.cluster_id
  cluster_name          = module.ecs_cluster.cluster_name
  image_uri             = var.gateway_image_uri
  container_port        = 8080
  cpu                   = var.gateway_cpu
  memory                = var.gateway_memory
  desired_count         = var.gateway_desired_count
  min_capacity          = var.gateway_min_capacity
  max_capacity          = var.gateway_max_capacity
  target_group_arn      = module.alb.gateway_target_group_arn
  alb_security_group_id = module.alb.alb_security_group_id
  log_group_name        = module.ecs_cluster.log_group_name
  aws_region            = var.aws_region

  environment_variables = {
    SPRING_PROFILES_ACTIVE = "prod"
    AWS_REGION             = var.aws_region
  }

  secrets = {
    SPRING_R2DBC_URL      = "${module.rds.db_secret_arn}:host::"
    SPRING_R2DBC_USERNAME = "${module.rds.db_secret_arn}:username::"
    SPRING_R2DBC_PASSWORD = "${module.rds.db_secret_arn}:password::"
  }

  depends_on = [module.alb, module.ecs_cluster]
}

# Payments service (disabled by default, enable via variable)
module "payments_service" {
  count  = var.enable_payments_service ? 1 : 0
  source = "../../modules/ecs-service"

  environment           = var.environment
  project_name          = var.project_name
  service_name          = "payments"
  vpc_id                = module.vpc.vpc_id
  private_subnet_ids    = module.vpc.private_subnet_ids
  cluster_id            = module.ecs_cluster.cluster_id
  cluster_name          = module.ecs_cluster.cluster_name
  image_uri             = var.payments_image_uri
  container_port        = 8080
  cpu                   = var.payments_cpu
  memory                = var.payments_memory
  desired_count         = var.payments_desired_count
  min_capacity          = var.payments_min_capacity
  max_capacity          = var.payments_max_capacity
  target_group_arn      = module.alb.gateway_target_group_arn # TODO: Create separate target group
  alb_security_group_id = module.alb.alb_security_group_id
  log_group_name        = module.ecs_cluster.log_group_name
  aws_region            = var.aws_region

  environment_variables = {
    SPRING_PROFILES_ACTIVE = "prod"
    AWS_REGION             = var.aws_region
  }

  secrets = {
    SPRING_R2DBC_URL      = "${module.rds.db_secret_arn}:host::"
    SPRING_R2DBC_USERNAME = "${module.rds.db_secret_arn}:username::"
    SPRING_R2DBC_PASSWORD = "${module.rds.db_secret_arn}:password::"
  }

  depends_on = [module.alb, module.ecs_cluster]
}
