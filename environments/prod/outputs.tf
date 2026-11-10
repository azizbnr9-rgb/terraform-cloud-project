output "environment" {
  description = "Environnement déployé."
  value       = var.environment
}

output "alb_url" {
  description = "URL publique de l'application."
  value       = module.load_balancer.alb_url
}

output "alb_dns_name" {
  description = "Nom DNS de l'ALB."
  value       = module.load_balancer.alb_dns_name
}

output "vpc_id" {
  description = "Identifiant du VPC."
  value       = module.network.vpc_id
}

output "availability_zones" {
  description = "Zones de disponibilité utilisées."
  value       = local.azs
}

output "asg_name" {
  description = "Nom de l'Auto Scaling Group (tests de panne et de scaling)."
  value       = module.compute.asg_name
}

output "db_endpoint" {
  description = "Point de terminaison privé RDS."
  value       = module.database.db_endpoint
}

output "db_address" {
  description = "Nom d'hôte privé RDS (test d'accès refusé depuis Internet)."
  value       = module.database.db_address
}

output "db_secret_arn" {
  description = "Secret Secrets Manager des identifiants RDS."
  value       = module.database.master_user_secret_arn
}

output "bucket_name" {
  description = "Bucket S3 applicatif."
  value       = module.storage.bucket_name
}
