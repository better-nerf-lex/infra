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
  certificate_arn             = var.enable_ssl_certificates ? module.acm.frontend_certificate_arn : ""
  price_class                 = "PriceClass_100"
  alb_dns_name                = module.alb.alb_dns_name

  depends_on = [module.s3_frontend, module.alb]
}

module "acm" {
  source = "../../modules/acm"

  providers = {
    aws.us_east_1 = aws.us_east_1
  }

  environment                       = var.environment
  project_name                      = var.project_name
  domain_name                       = var.domain_name
  api_subdomain                     = var.api_domain
  frontend_subdomain                = var.frontend_domain
  use_route53                       = var.use_route53
  existing_api_certificate_arn      = var.existing_api_certificate_arn
  existing_frontend_certificate_arn = var.existing_frontend_certificate_arn
}

# Route53 record for Frontend (points to CloudFront)
# Only created if Route 53 is used for DNS management
resource "aws_route53_record" "frontend" {
  count   = var.use_route53 ? 1 : 0
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

  environment             = var.environment
  project_name            = var.project_name
  vpc_id                  = module.vpc.vpc_id
  public_subnet_ids       = module.vpc.public_subnet_ids
  certificate_arn         = var.enable_ssl_certificates ? module.acm.api_certificate_arn : ""
  enable_payments_service = var.enable_payments_service
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

module "opensearch" {
  count  = var.enable_elasticsearch ? 1 : 0
  source = "../../modules/opensearch"

  environment        = var.environment
  project_name       = var.project_name
  vpc_id             = module.vpc.vpc_id
  private_subnet_ids = module.vpc.private_subnet_ids

  depends_on = [module.vpc]
}

resource "aws_security_group_rule" "opensearch_ingress_vpc" {
  count             = var.enable_elasticsearch ? 1 : 0
  type              = "ingress"
  from_port         = 443
  to_port           = 443
  protocol          = "tcp"
  security_group_id = module.opensearch[0].security_group_id
  cidr_blocks       = [module.vpc.vpc_cidr]
  description       = "Allow HTTPS from within VPC to OpenSearch"
}

resource "aws_security_group_rule" "opensearch_ingress_gateway" {
  count                    = var.enable_elasticsearch ? 1 : 0
  type                     = "ingress"
  from_port                = 443
  to_port                  = 443
  protocol                 = "tcp"
  security_group_id        = module.opensearch[0].security_group_id
  source_security_group_id = module.gateway_service.security_group_id
  description              = "Allow HTTPS from gateway to OpenSearch"
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

# RDS schema initialization via Lambda
module "rds_init" {
  source = "../../modules/rds-init-lambda"

  environment          = var.environment
  project_name         = var.project_name
  db_host              = module.rds.db_address
  db_name              = module.rds.db_name
  db_secret_arn        = module.rds.db_secret_arn
  vpc_id               = module.vpc.vpc_id
  private_subnet_ids   = module.vpc.private_subnet_ids
  db_security_group_id = module.rds.db_security_group_id

  depends_on = [module.rds]
}


module "iam" {
  source = "../../modules/iam"

  environment         = var.environment
  project_name        = var.project_name
  github_org          = var.github_org
  github_repositories = var.github_repositories
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
    FILE_SERVICE_URL       = "http://file-service.${var.environment}.${var.project_name}.local:8080"
    ELASTICSEARCH_URL      = var.enable_elasticsearch ? "https://${module.opensearch[0].domain_endpoint}" : ""
    ELASTICSEARCH_ENABLED  = var.enable_elasticsearch ? "true" : "false"
    DB_HOST                = module.rds.db_address
    DB_PORT                = "5432"
    DB_NAME                = module.rds.db_name
    COGNITO_USER_POOL_ID   = module.cognito.user_pool_id
    COGNITO_CLIENT_ID      = module.cognito.user_pool_client_id
  }

  service_registries = {
    registry_arn = aws_service_discovery_service.gateway.arn
  }

  secrets = {
    SPRING_R2DBC_USERNAME       = "${module.rds.db_secret_arn}:username::"
    SPRING_R2DBC_PASSWORD       = "${module.rds.db_secret_arn}:password::"
    SPRING_AI_ANTHROPIC_API_KEY = "${aws_secretsmanager_secret.gateway_secrets.arn}:anthropic_api_key::"
    JWT_SECRET                  = "${aws_secretsmanager_secret.gateway_secrets.arn}:jwt_secret::"
    GOOGLE_CLIENT_ID            = "${aws_secretsmanager_secret.gateway_secrets.arn}:google_client_id::"
    GOOGLE_CLIENT_SECRET        = "${aws_secretsmanager_secret.gateway_secrets.arn}:google_client_secret::"
  }

  depends_on = [module.alb, module.ecs_cluster]
}

resource "aws_secretsmanager_secret" "gateway_secrets" {
  name        = "${var.environment}/${var.project_name}/gateway-secrets"
  description = "Detailed secrets for gateway service"
}

resource "aws_secretsmanager_secret_version" "gateway_secrets" {
  secret_id = aws_secretsmanager_secret.gateway_secrets.id
  secret_string = jsonencode({
    anthropic_api_key    = var.anthropic_api_key
    jwt_secret           = var.jwt_secret
    google_client_id     = var.google_client_id
    google_client_secret = var.google_client_secret
  })
}

resource "aws_service_discovery_private_dns_namespace" "internal" {
  name        = "${var.environment}.${var.project_name}.local"
  description = "Internal service discovery namespace"
  vpc         = module.vpc.vpc_id
}

resource "aws_service_discovery_service" "gateway" {
  name = "gateway"

  dns_config {
    namespace_id = aws_service_discovery_private_dns_namespace.internal.id

    dns_records {
      ttl  = 10
      type = "A"
    }

    routing_policy = "MULTIVALUE"
  }

  health_check_custom_config {
    failure_threshold = 1
  }
}

resource "aws_service_discovery_service" "file_service" {
  name = "file-service"

  dns_config {
    namespace_id = aws_service_discovery_private_dns_namespace.internal.id

    dns_records {
      ttl  = 10
      type = "A"
    }

    routing_policy = "MULTIVALUE"
  }

  health_check_custom_config {
    failure_threshold = 1
  }
}

module "file_service" {
  source = "../../modules/ecs-service"

  environment           = var.environment
  project_name          = var.project_name
  service_name          = "file-service"
  vpc_id                = module.vpc.vpc_id
  private_subnet_ids    = module.vpc.private_subnet_ids
  cluster_id            = module.ecs_cluster.cluster_id
  cluster_name          = module.ecs_cluster.cluster_name
  image_uri             = var.file_service_image_uri
  container_port        = 8080
  cpu                   = var.file_service_cpu
  memory                = var.file_service_memory
  desired_count         = var.file_service_desired_count
  min_capacity          = var.file_service_min_capacity
  max_capacity          = var.file_service_max_capacity
  # No target_group_arn - internal service only
  # No alb_security_group_id - internal service only
  log_group_name        = module.ecs_cluster.log_group_name
  aws_region            = var.aws_region
  health_check_path     = "/health"

  service_registries = {
    registry_arn = aws_service_discovery_service.file_service.arn
  }

  environment_variables = {
    NODE_ENV              = "production"
    PORT                  = "8080"
    AWS_REGION            = var.aws_region
    AWS_S3_BUCKET         = "${var.environment}-${var.project_name}-documents"
    ELASTICSEARCH_URL     = var.enable_elasticsearch ? "https://${module.opensearch[0].domain_endpoint}" : ""
    ELASTICSEARCH_ENABLED = var.enable_elasticsearch ? "true" : "false"
  }

  depends_on = [module.ecs_cluster]
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
  target_group_arn      = module.alb.payments_target_group_arn
  alb_security_group_id = module.alb.alb_security_group_id
  log_group_name        = module.ecs_cluster.log_group_name
  aws_region            = var.aws_region

  environment_variables = {
    SPRING_PROFILES_ACTIVE = "prod"
    AWS_REGION             = var.aws_region
    ELASTICSEARCH_URL      = var.enable_elasticsearch ? "https://${module.opensearch[0].domain_endpoint}" : ""
  }

  secrets = {
    SPRING_R2DBC_URL      = "${module.rds.db_secret_arn}:host::"
    SPRING_R2DBC_USERNAME = "${module.rds.db_secret_arn}:username::"
    SPRING_R2DBC_PASSWORD = "${module.rds.db_secret_arn}:password::"
  }

  depends_on = [module.alb, module.ecs_cluster]
}
