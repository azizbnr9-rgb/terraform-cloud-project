output "alb_sg_id" {
  description = "Security Group de l'ALB."
  value       = aws_security_group.alb.id
}

output "app_sg_id" {
  description = "Security Group des instances applicatives."
  value       = aws_security_group.app.id
}

output "db_sg_id" {
  description = "Security Group de la base de données."
  value       = aws_security_group.db.id
}

output "instance_profile_name" {
  description = "Nom du profil d'instance IAM des EC2."
  value       = var.create_iam_role ? aws_iam_instance_profile.ec2[0].name : var.existing_instance_profile_name
}

output "ec2_role_arn" {
  description = "ARN du rôle IAM des EC2."
  value       = var.create_iam_role ? aws_iam_role.ec2[0].arn : null
}
