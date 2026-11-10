output "asg_name" {
  description = "Nom de l'Auto Scaling Group."
  value       = aws_autoscaling_group.app.name
}

output "asg_arn" {
  description = "ARN de l'Auto Scaling Group."
  value       = aws_autoscaling_group.app.arn
}

output "launch_template_id" {
  description = "Identifiant du Launch Template."
  value       = aws_launch_template.app.id
}

output "ami_id" {
  description = "AMI utilisée par le Launch Template."
  value       = data.aws_ssm_parameter.ami.value
  sensitive   = true
}
