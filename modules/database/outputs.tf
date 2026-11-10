output "db_endpoint" {
  description = "Point de terminaison privé de la base (hôte:port)."
  value       = aws_db_instance.this.endpoint
}

output "db_address" {
  description = "Nom d'hôte privé de la base."
  value       = aws_db_instance.this.address
}

output "db_port" {
  description = "Port de la base."
  value       = aws_db_instance.this.port
}

output "db_name" {
  description = "Nom de la base initiale."
  value       = aws_db_instance.this.db_name
}

output "master_user_secret_arn" {
  description = "ARN du secret Secrets Manager contenant les identifiants administrateur."
  value       = aws_db_instance.this.master_user_secret[0].secret_arn
}
