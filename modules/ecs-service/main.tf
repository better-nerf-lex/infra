data "aws_vpc" "selected" {
  id = var.vpc_id
}

resource "aws_security_group" "ecs_tasks" {
  name        = "${var.environment}-${var.service_name}-sg"
  description = "Security group for ECS tasks"
  vpc_id      = var.vpc_id

  # Allow traffic from ALB (only for public services)
  dynamic "ingress" {
    for_each = var.alb_security_group_id != null ? [1] : []
    content {
      from_port       = var.container_port
      to_port         = var.container_port
      protocol        = "tcp"
      security_groups = [var.alb_security_group_id]
      description     = "Allow traffic from ALB"
    }
  }

  # Allow traffic from VPC (for internal-only services)
  dynamic "ingress" {
    for_each = var.alb_security_group_id == null ? [1] : []
    content {
      from_port   = var.container_port
      to_port     = var.container_port
      protocol    = "tcp"
      cidr_blocks = [data.aws_vpc.selected.cidr_block]
      description = "Allow traffic from VPC for internal services"
    }
  }

  dynamic "ingress" {
    for_each = var.additional_ingress_security_groups
    content {
      from_port       = var.container_port
      to_port         = var.container_port
      protocol        = "tcp"
      security_groups = [ingress.value.security_group_id]
      description     = ingress.value.description
    }
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
    description = "Allow all outbound traffic"
  }

  tags = {
    Name        = "${var.environment}-${var.service_name}-sg"
    Environment = var.environment
    Project     = var.project_name
    Service     = var.service_name
  }
}

resource "aws_iam_role" "ecs_task_execution" {
  name = "${var.environment}-${var.service_name}-exec-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action = "sts:AssumeRole"
      Effect = "Allow"
      Principal = {
        Service = "ecs-tasks.amazonaws.com"
      }
    }]
  })

  tags = {
    Name        = "${var.environment}-${var.service_name}-exec-role"
    Environment = var.environment
    Project     = var.project_name
    Service     = var.service_name
  }
}

resource "aws_iam_role_policy_attachment" "ecs_task_execution" {
  role       = aws_iam_role.ecs_task_execution.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}

resource "aws_iam_role_policy" "ecs_task_execution_secrets" {
  name = "${var.environment}-${var.service_name}-secrets-policy"
  role = aws_iam_role.ecs_task_execution.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Action = [
        "secretsmanager:GetSecretValue",
        "kms:Decrypt"
      ]
      Resource = "*"
    }]
  })
}

resource "aws_iam_role" "ecs_task" {
  name = "${var.environment}-${var.service_name}-task-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action = "sts:AssumeRole"
      Effect = "Allow"
      Principal = {
        Service = "ecs-tasks.amazonaws.com"
      }
    }]
  })

  tags = {
    Name        = "${var.environment}-${var.service_name}-task-role"
    Environment = var.environment
    Project     = var.project_name
    Service     = var.service_name
  }
}

resource "aws_ecs_task_definition" "main" {
  family                   = "${var.environment}-${var.service_name}"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = var.cpu
  memory                   = var.memory
  execution_role_arn       = aws_iam_role.ecs_task_execution.arn
  task_role_arn            = aws_iam_role.ecs_task.arn

  container_definitions = jsonencode([{
    name      = var.service_name
    image     = var.image_uri
    essential = true

    portMappings = [{
      containerPort = var.container_port
      protocol      = "tcp"
    }]

    environment = [
      for key, value in var.environment_variables : {
        name  = key
        value = value
      }
    ]

    secrets = [
      for key, value in var.secrets : {
        name      = key
        valueFrom = value
      }
    ]

    logConfiguration = {
      logDriver = "awslogs"
      options = {
        "awslogs-group"         = var.log_group_name
        "awslogs-region"        = var.aws_region
        "awslogs-stream-prefix" = var.service_name
      }
    }

    healthCheck = {
      command     = var.container_health_check_command != null ? var.container_health_check_command : ["CMD-SHELL", "curl -f http://localhost:${var.container_port}${var.health_check_path} || exit 1"]
      interval    = 30
      timeout     = 5
      retries     = 3
      startPeriod = var.container_health_check_start_period_seconds
    }
  }])

  tags = {
    Name        = "${var.environment}-${var.service_name}"
    Environment = var.environment
    Project     = var.project_name
    Service     = var.service_name
  }
}

resource "aws_ecs_service" "main" {
  name            = "${var.environment}-${var.service_name}"
  cluster         = var.cluster_id
  task_definition = aws_ecs_task_definition.main.arn
  desired_count   = var.desired_count
  launch_type     = "FARGATE"

  # Allow time for app startup before ALB health checks fail the task
  health_check_grace_period_seconds = var.target_group_arn != null ? var.health_check_grace_period_seconds : null

  network_configuration {
    subnets          = var.private_subnet_ids
    security_groups  = [aws_security_group.ecs_tasks.id]
    assign_public_ip = false
  }

  # Load balancer configuration only for public services
  dynamic "load_balancer" {
    for_each = var.target_group_arn != null ? [1] : []
    content {
      target_group_arn = var.target_group_arn
      container_name   = var.service_name
      container_port   = var.container_port
    }
  }

  dynamic "service_registries" {
    for_each = var.service_registries != null ? [var.service_registries] : []
    content {
      registry_arn = service_registries.value.registry_arn
    }
  }

  deployment_controller {
    type = "ECS"
  }

  deployment_circuit_breaker {
    enable   = true
    rollback = true
  }

  deployment_maximum_percent         = 200
  deployment_minimum_healthy_percent = 100

  depends_on = [aws_iam_role_policy_attachment.ecs_task_execution]

  tags = {
    Name        = "${var.environment}-${var.service_name}"
    Environment = var.environment
    Project     = var.project_name
    Service     = var.service_name
  }

  lifecycle {
    ignore_changes = [
      task_definition
    ]
  }
}

resource "aws_appautoscaling_target" "ecs" {
  max_capacity       = var.max_capacity
  min_capacity       = var.min_capacity
  resource_id        = "service/${var.cluster_name}/${aws_ecs_service.main.name}"
  scalable_dimension = "ecs:service:DesiredCount"
  service_namespace  = "ecs"
}

resource "aws_appautoscaling_policy" "ecs_cpu" {
  name               = "${var.environment}-${var.service_name}-cpu-scaling"
  policy_type        = "TargetTrackingScaling"
  resource_id        = aws_appautoscaling_target.ecs.resource_id
  scalable_dimension = aws_appautoscaling_target.ecs.scalable_dimension
  service_namespace  = aws_appautoscaling_target.ecs.service_namespace

  target_tracking_scaling_policy_configuration {
    predefined_metric_specification {
      predefined_metric_type = "ECSServiceAverageCPUUtilization"
    }
    target_value = 70.0
  }
}

resource "aws_appautoscaling_policy" "ecs_memory" {
  name               = "${var.environment}-${var.service_name}-memory-scaling"
  policy_type        = "TargetTrackingScaling"
  resource_id        = aws_appautoscaling_target.ecs.resource_id
  scalable_dimension = aws_appautoscaling_target.ecs.scalable_dimension
  service_namespace  = aws_appautoscaling_target.ecs.service_namespace

  target_tracking_scaling_policy_configuration {
    predefined_metric_specification {
      predefined_metric_type = "ECSServiceAverageMemoryUtilization"
    }
    target_value = 80.0
  }
}
