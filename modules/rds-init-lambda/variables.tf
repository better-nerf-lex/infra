variable "environment" {
  description = "Environment name (dev, prod)"
  type        = string
}

variable "project_name" {
  description = "Project name for resource tagging"
  type        = string
  default     = "paragrafic"
}

variable "db_host" {
  description = "RDS database hostname"
  type        = string
}

variable "db_name" {
  description = "Database name"
  type        = string
}

variable "db_secret_arn" {
  description = "ARN of Secrets Manager secret containing database credentials"
  type        = string
}

variable "vpc_id" {
  description = "VPC ID where Lambda will run"
  type        = string
}

variable "private_subnet_ids" {
  description = "List of private subnet IDs for Lambda"
  type        = list(string)
}

variable "db_security_group_id" {
  description = "Security group ID of the RDS instance"
  type        = string
}

variable "db_instance_id" {
  description = "RDS instance ID — used to re-trigger schema init when the DB is recreated"
  type        = string
}

variable "extra_databases" {
  description = "Additional sibling databases to create on the same cluster (e.g. subscription_service). Lambda only creates the DB; schema is owned by the service itself."
  type        = list(string)
  default     = []
}
