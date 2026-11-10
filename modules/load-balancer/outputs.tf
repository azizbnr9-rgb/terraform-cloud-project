output "alb_arn" {
  description = "ARN de l'ALB."
  value       = aws_lb.this.arn
}

output "alb_dns_name" {
  description = "Nom DNS public de l'ALB."
  value       = aws_lb.this.dns_name
}

output "alb_url" {
  description = "URL d'accès à l'application."
  value       = "${local.https_enabled ? "https" : "http"}://${aws_lb.this.dns_name}"
}

output "target_group_arn" {
  description = "ARN du Target Group (utilisé par l'Auto Scaling Group)."
  value       = aws_lb_target_group.app.arn
}

output "alb_arn_suffix" {
  description = "Suffixe ARN de l'ALB (métriques CloudWatch)."
  value       = aws_lb.this.arn_suffix
}

output "target_group_arn_suffix" {
  description = "Suffixe ARN du Target Group (métriques CloudWatch)."
  value       = aws_lb_target_group.app.arn_suffix
}
