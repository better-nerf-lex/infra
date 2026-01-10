output "alb_arn" {
  description = "ARN of the Application Load Balancer"
  value       = aws_lb.main.arn
}

output "alb_dns_name" {
  description = "DNS name of the Application Load Balancer"
  value       = aws_lb.main.dns_name
}

output "alb_zone_id" {
  description = "Zone ID of the Application Load Balancer"
  value       = aws_lb.main.zone_id
}

output "gateway_target_group_arn" {
  description = "ARN of the gateway target group"
  value       = aws_lb_target_group.gateway.arn
}

output "payments_target_group_arn" {
  description = "ARN of the payments target group"
  value       = var.enable_payments_service ? aws_lb_target_group.payments[0].arn : ""
}

output "alb_security_group_id" {
  description = "Security group ID of the ALB"
  value       = aws_security_group.alb.id
}

output "file_service_target_group_arn" {
  description = "ARN of the file service target group"
  value       = aws_lb_target_group.file_service.arn
}
