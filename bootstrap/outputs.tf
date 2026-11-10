output "state_bucket" {
  description = "Bucket à passer à terraform init -backend-config=\"bucket=...\"."
  value       = local.bucket_id
}

output "aws_region" {
  description = "Région du backend."
  value       = var.aws_region
}

output "github_plan_role_arn" {
  description = "Rôle OIDC du pipeline pour terraform plan (secret AWS_PLAN_ROLE_ARN)."
  value       = var.create_github_oidc ? aws_iam_role.plan[0].arn : null
}

output "github_apply_role_arn" {
  description = "Rôle OIDC du pipeline pour terraform apply (secret AWS_APPLY_ROLE_ARN)."
  value       = var.create_github_oidc ? aws_iam_role.apply[0].arn : null
}
