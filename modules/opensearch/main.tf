resource "aws_security_group" "opensearch" {
  name        = "${var.environment}-opensearch-sg"
  description = "Security group for OpenSearch"
  vpc_id      = var.vpc_id

  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"] # Should be restricted to VPC CIDR in production
    description = "Allow HTTPS for OpenSearch"
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
    description = "Allow all outbound traffic"
  }

  tags = {
    Name        = "${var.environment}-opensearch-sg"
    Environment = var.environment
    Project     = var.project_name
  }
}

resource "aws_opensearch_domain" "main" {
  domain_name    = "${var.environment}-${var.project_name}-search"
  engine_version = var.engine_version

  cluster_config {
    instance_type          = var.instance_type
    instance_count         = 1
    dedicated_master_enabled = false
    zone_awareness_enabled   = false
  }

  vpc_options {
    subnet_ids         = [var.private_subnet_ids[0]]
    security_group_ids = [aws_security_group.opensearch.id]
  }

  ebs_options {
    ebs_enabled = true
    volume_size = var.ebs_volume_size
    volume_type = "gp3"
  }

  encrypt_at_rest {
    enabled = true
  }

  node_to_node_encryption {
    enabled = true
  }

  domain_endpoint_options {
    enforce_https       = true
    tls_security_policy = "Policy-Min-TLS-1-2-2019-07"
  }

  advanced_security_options {
    enabled                        = false # Simplified for dev
    internal_user_database_enabled = false
  }

  access_policies = <<CONFIG
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Action": "es:*",
            "Principal": "*",
            "Effect": "Allow",
            "Resource": "arn:aws:es:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:domain/${var.environment}-${var.project_name}-search/*"
        }
    ]
}
CONFIG

  tags = {
    Name        = "${var.environment}-opensearch"
    Environment = var.environment
    Project     = var.project_name
  }
}

data "aws_region" "current" {}
data "aws_caller_identity" "current" {}
