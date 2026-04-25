resource "aws_security_group" "alb" {
  name        = "${var.environment}-alb-sg"
  description = "Security group for ALB"
  vpc_id      = var.vpc_id

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    description = "Allow HTTP from internet"
  }

  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    description = "Allow HTTPS from internet"
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
    description = "Allow all outbound traffic"
  }

  tags = {
    Name        = "${var.environment}-alb-sg"
    Environment = var.environment
    Project     = var.project_name
  }
}

resource "aws_lb" "main" {
  name               = "${var.environment}-alb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.alb.id]
  subnets            = var.public_subnet_ids

  enable_deletion_protection = var.environment == "prod" ? true : false
  enable_http2               = true

  tags = {
    Name        = "${var.environment}-alb"
    Environment = var.environment
    Project     = var.project_name
  }
}

resource "aws_lb_target_group" "gateway" {
  name        = "${var.environment}-gateway-tg"
  port        = 8080
  protocol    = "HTTP"
  vpc_id      = var.vpc_id
  target_type = "ip"

  health_check {
    enabled             = true
    healthy_threshold   = 2
    unhealthy_threshold = 3
    timeout             = 5
    interval            = 30
    path                = "/actuator/health"
    matcher             = "200"
  }

  deregistration_delay = 30

  tags = {
    Name        = "${var.environment}-gateway-tg"
    Environment = var.environment
    Project     = var.project_name
  }
}

resource "aws_lb_target_group" "payments" {
  count       = var.enable_payments_service ? 1 : 0
  name        = "${var.environment}-payments-tg"
  port        = 8080
  protocol    = "HTTP"
  vpc_id      = var.vpc_id
  target_type = "ip"

  health_check {
    enabled             = true
    healthy_threshold   = 2
    unhealthy_threshold = 3
    timeout             = 5
    interval            = 30
    path                = "/actuator/health"
    matcher             = "200"
  }

  deregistration_delay = 30

  tags = {
    Name        = "${var.environment}-payments-tg"
    Environment = var.environment
    Project     = var.project_name
  }
}

resource "aws_lb_target_group" "subscription_webhook" {
  name        = "${var.environment}-sub-webhook-tg"
  port        = 8080
  protocol    = "HTTP"
  vpc_id      = var.vpc_id
  target_type = "ip"

  health_check {
    enabled             = true
    healthy_threshold   = 2
    unhealthy_threshold = 3
    timeout             = 5
    interval            = 30
    path                = "/health"
    matcher             = "200"
  }

  deregistration_delay = 30

  tags = {
    Name        = "${var.environment}-sub-webhook-tg"
    Environment = var.environment
    Project     = var.project_name
  }
}

# File service is accessed via AWS Cloud Map service discovery
# URL: http://file-service.dev.paragrafic.local:8080

# resource "aws_lb_target_group" "file_service" {
#   name        = "${var.environment}-file-service-tg"
#   port        = 8080
#   protocol    = "HTTP"
#   vpc_id      = var.vpc_id
#   target_type = "ip"
#
#   health_check {
#     enabled             = true
#     healthy_threshold   = 2
#     unhealthy_threshold = 3
#     timeout             = 5
#     interval            = 30
#     path                = "/actuator/health"
#     matcher             = "200"
#   }
#
#   deregistration_delay = 30
#
#   tags = {
#     Name        = "${var.environment}-file-service-tg"
#     Environment = var.environment
#     Project     = var.project_name
#   }
# }


resource "aws_lb_listener" "http" {
  load_balancer_arn = aws_lb.main.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type = "redirect"

    redirect {
      port        = "443"
      protocol    = "HTTPS"
      status_code = "HTTP_301"
    }
  }
}

resource "aws_lb_listener" "https" {
  count             = var.certificate_arn != "" ? 1 : 0
  load_balancer_arn = aws_lb.main.arn
  port              = 443
  protocol          = "HTTPS"
  ssl_policy        = "ELBSecurityPolicy-TLS13-1-2-2021-06"
  certificate_arn   = var.certificate_arn

  default_action {
    type = "fixed-response"

    fixed_response {
      content_type = "application/json"
      message_body = jsonencode({
        error   = "Not Found"
        message = "The requested API endpoint does not exist"
      })
      status_code = "404"
    }
  }
}

resource "aws_lb_listener_rule" "gateway" {
  count        = var.certificate_arn != "" ? 1 : 0
  listener_arn = aws_lb_listener.https[0].arn
  priority     = 100

  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.gateway.arn
  }

  condition {
    path_pattern {
      # Route all paths to gateway - CloudFront already filters /api/* prefix
      values = ["/*"]
    }
  }
}

resource "aws_lb_listener_rule" "subscription_webhook" {
  count        = var.certificate_arn != "" ? 1 : 0
  listener_arn = aws_lb_listener.https[0].arn
  priority     = 90

  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.subscription_webhook.arn
  }

  condition {
    path_pattern {
      values = ["/webhooks/stripe"]
    }
  }
}

resource "aws_lb_listener_rule" "payments" {
  count        = var.enable_payments_service && var.certificate_arn != "" ? 1 : 0
  listener_arn = aws_lb_listener.https[0].arn
  priority     = 101

  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.payments[0].arn
  }

  condition {
    path_pattern {
      values = ["/api/payments/*"]
    }
  }
}

# File service is internal-only, accessed via service discovery
# No public ALB routing for file-service
# Gateway calls it at: http://file-service.dev.paragrafic.local:8080

# resource "aws_lb_listener_rule" "file_service" {
#   count        = var.certificate_arn != "" ? 1 : 0
#   listener_arn = aws_lb_listener.https[0].arn
#   priority     = 102
#
#   action {
#     type             = "forward"
#     target_group_arn = aws_lb_target_group.file_service.arn
#   }
#
#   condition {
#     path_pattern {
#       values = ["/api/files/*"]
#     }
#   }
# }
