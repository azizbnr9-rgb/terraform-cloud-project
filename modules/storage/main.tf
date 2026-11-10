data "aws_caller_identity" "current" {}
data "aws_region" "current" {}
data "aws_elb_service_account" "current" {}
data "aws_partition" "current" {}

locals {
  # Nom globalement unique : <prefixe>-assets-<compte>-<region>
  bucket_name = "${var.name_prefix}-assets-${data.aws_caller_identity.current.account_id}-${data.aws_region.current.name}"
  region      = data.aws_region.current.name

  bucket_id  = var.create_bucket_with_cli ? terraform_data.bucket_cli[0].output.bucket : aws_s3_bucket.this[0].id
  bucket_arn = "arn:${data.aws_partition.current.partition}:s3:::${local.bucket_id}"
}

# Cas standard : bucket géré par la ressource aws_s3_bucket
resource "aws_s3_bucket" "this" {
  count = var.create_bucket_with_cli ? 0 : 1

  bucket        = local.bucket_name
  force_destroy = var.force_destroy

  tags = merge(var.tags, { Name = local.bucket_name })
}

# AWS Academy Learner Lab : une SCP interdit s3:GetBucketObjectLockConfiguration,
# lu par aws_s3_bucket après création. Le bucket est alors créé/supprimé par l'AWS CLI,
# toutes ses propriétés (versioning, chiffrement, accès public, politique, cycle de vie)
# restant gérées par Terraform ci-dessous.
resource "terraform_data" "bucket_cli" {
  count = var.create_bucket_with_cli ? 1 : 0

  input = {
    bucket        = local.bucket_name
    region        = local.region
    force_destroy = var.force_destroy
    script        = "${path.module}/scripts/delete-bucket.sh"
  }

  provisioner "local-exec" {
    command = "aws s3api head-bucket --bucket ${self.input.bucket} 2>/dev/null || aws s3api create-bucket --bucket ${self.input.bucket} --region ${self.input.region} ${self.input.region == "us-east-1" ? "" : "--create-bucket-configuration LocationConstraint=${self.input.region}"}"
  }

  provisioner "local-exec" {
    when    = destroy
    command = "bash ${self.input.script} ${self.input.bucket} ${self.input.force_destroy}"
  }
}

resource "aws_s3_bucket_ownership_controls" "this" {
  bucket = local.bucket_id

  rule {
    object_ownership = "BucketOwnerEnforced"
  }
}

resource "aws_s3_bucket_public_access_block" "this" {
  bucket = local.bucket_id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_versioning" "this" {
  bucket = local.bucket_id

  versioning_configuration {
    status = "Enabled"
  }
}

# SSE-S3 (AES-256) : seul chiffrement accepté par les journaux d'accès ALB
resource "aws_s3_bucket_server_side_encryption_configuration" "this" {
  bucket = local.bucket_id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
    bucket_key_enabled = true
  }
}

resource "aws_s3_bucket_lifecycle_configuration" "this" {
  bucket = local.bucket_id

  rule {
    id     = "expire-alb-logs"
    status = "Enabled"

    filter {
      prefix = "alb-logs/"
    }

    transition {
      days          = 30
      storage_class = "STANDARD_IA"
    }

    expiration {
      days = var.log_retention_days
    }
  }

  rule {
    id     = "backups-to-glacier"
    status = "Enabled"

    filter {
      prefix = "backups/"
    }

    transition {
      days          = 30
      storage_class = "GLACIER_IR"
    }
  }

  rule {
    id     = "cleanup-noncurrent-and-multipart"
    status = "Enabled"

    filter {}

    noncurrent_version_expiration {
      noncurrent_days = var.noncurrent_version_days
    }

    abort_incomplete_multipart_upload {
      days_after_initiation = 7
    }
  }

  depends_on = [aws_s3_bucket_versioning.this]
}

data "aws_iam_policy_document" "bucket" {
  # Refuse toute requête non chiffrée en transit
  statement {
    sid     = "DenyInsecureTransport"
    effect  = "Deny"
    actions = ["s3:*"]
    resources = [
      local.bucket_arn,
      "${local.bucket_arn}/*",
    ]

    principals {
      type        = "*"
      identifiers = ["*"]
    }

    condition {
      test     = "Bool"
      variable = "aws:SecureTransport"
      values   = ["false"]
    }
  }

  # Autorise le service ELB de la région à déposer les journaux d'accès ALB
  statement {
    sid       = "AllowAlbAccessLogs"
    effect    = "Allow"
    actions   = ["s3:PutObject"]
    resources = ["${local.bucket_arn}/alb-logs/AWSLogs/${data.aws_caller_identity.current.account_id}/*"]

    principals {
      type        = "AWS"
      identifiers = [data.aws_elb_service_account.current.arn]
    }
  }
}

resource "aws_s3_bucket_policy" "this" {
  bucket = local.bucket_id
  policy = data.aws_iam_policy_document.bucket.json

  depends_on = [aws_s3_bucket_public_access_block.this]
}
