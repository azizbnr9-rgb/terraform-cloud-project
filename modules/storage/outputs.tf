output "bucket_name" {
  description = "Nom du bucket applicatif."
  value       = aws_s3_bucket.this.bucket
}

output "bucket_arn" {
  description = "ARN du bucket applicatif."
  value       = aws_s3_bucket.this.arn
}
