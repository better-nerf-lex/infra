variable "environment" {
  description = "Environment name (dev, prod)"
  type        = string
}

variable "project_name" {
  description = "Project name for resource tagging"
  type        = string
  default     = "paragrafic"
}

variable "service_name" {
  description = "Name of the service"
  type        = string
}

variable "vpc_id" {
  description = "VPC ID"
  type        = string
}

variable "private_subnet_ids" {
  description = "List of private subnet IDs for ECS tasks"
  type        = list(string)
}

variable "cluster_id" {
  description = "ECS cluster ID"
  type        = string
}

variable "cluster_name" {
  description = "ECS cluster name"
  type        = string
}

variable "image_uri" {
  description = "Docker image URI"
  type        = string
}

variable "container_port" {
  description = "Port exposed by the container"
  type        = number
  default     = 8080
}

variable "cpu" {
  description = "CPU units for the task (256 = 0.25 vCPU, 512 = 0.5 vCPU, 1024 = 1 vCPU)"
  type        = number
  default     = 256
}

variable "memory" {
  description = "Memory for the task in MB"
  type        = number
  default     = 512
}

variable "desired_count" {
  description = "Desired number of tasks"
  type        = number
  default     = 1
}

variable "min_capacity" {
  description = "Minimum number of tasks for autoscaling"
  type        = number
  default     = 1
}

variable "max_capacity" {
  description = "Maximum number of tasks for autoscaling" 
  type        = number
  default     = 3
}

variable "target_group_arn" {
  description = "Target group ARN for load balancer"
  type        = string
  default     = null
}

variable "alb_security_group_id" {
  description = "Security group ID of the ALB"
  type        = string
  default     = null
}

variable "log_group_name" {
  description = "CloudWatch log group name"
  type        = string
}

variable "aws_region" {
  description = "AWS region"
  type        = string
}

variable "environment_variables" {
  description = "Environment variables for the container"
  type        = map(string)
  default     = {}
}

variable "secrets" {
  description = "Secrets from AWS Secrets Manager (map of name to ARN)"
  type        = map(string)
  default     = {}
}

variable "service_registries" {
  description = "Service discovery registries for the service"
  type = object({
    registry_arn = string
  })
  default = null
}

variable "health_check_path" {
  description = "Health check endpoint path"
  type        = string
  default     = "/actuator/health"
}
