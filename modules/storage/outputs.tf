output "bucket_name" {
  description = "Nom du bucket applicatif."
  value       = local.bucket_id
}

output "bucket_arn" {
  description = "ARN du bucket applicatif."
  value       = local.bucket_arn
}
