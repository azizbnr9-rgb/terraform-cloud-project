# ---------------------------------------------------------------------------
# BOOTSTRAP : crée le bucket du backend distant AVANT le projet principal.
# Son propre état reste local (fichier terraform.tfstate de ce dossier, ignoré par Git).
# ---------------------------------------------------------------------------
terraform {
  required_version = ">= 1.10.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = var.aws_region

  default_tags {
    tags = {
      Project     = var.project_name
      Environment = "shared"
      ManagedBy   = "Terraform"
      Owner       = var.owner
    }
  }
}

data "aws_caller_identity" "current" {}

data "aws_partition" "current" {}

locals {
  state_bucket = "${var.project_name}-tfstate-${data.aws_caller_identity.current.account_id}-${var.aws_region}"

  bucket_id  = var.create_bucket_with_cli ? terraform_data.state_cli[0].output.bucket : aws_s3_bucket.state[0].id
  bucket_arn = "arn:${data.aws_partition.current.partition}:s3:::${local.bucket_id}"
}

resource "aws_s3_bucket" "state" {
  count = var.create_bucket_with_cli ? 0 : 1

  bucket = local.state_bucket

  # Les états sont précieux : jamais de suppression accidentelle avec des objets dedans
  force_destroy = var.force_destroy

  tags = { Name = local.state_bucket }
}

# Learner Lab : bucket créé par l'AWS CLI (voir modules/storage pour l'explication de la SCP)
resource "terraform_data" "state_cli" {
  count = var.create_bucket_with_cli ? 1 : 0

  input = {
    bucket        = local.state_bucket
    region        = var.aws_region
    force_destroy = var.force_destroy
    script        = "${path.module}/../modules/storage/scripts/delete-bucket.sh"
  }

  provisioner "local-exec" {
    command = "aws s3api head-bucket --bucket ${self.input.bucket} 2>/dev/null || aws s3api create-bucket --bucket ${self.input.bucket} --region ${self.input.region} ${self.input.region == "us-east-1" ? "" : "--create-bucket-configuration LocationConstraint=${self.input.region}"}"
  }

  provisioner "local-exec" {
    when    = destroy
    command = "bash ${self.input.script} ${self.input.bucket} ${self.input.force_destroy}"
  }
}

resource "aws_s3_bucket_versioning" "state" {
  bucket = local.bucket_id

  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "state" {
  bucket = local.bucket_id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "aws:kms"
    }
    bucket_key_enabled = true
  }
}

resource "aws_s3_bucket_public_access_block" "state" {
  bucket = local.bucket_id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_ownership_controls" "state" {
  bucket = local.bucket_id

  rule {
    object_ownership = "BucketOwnerEnforced"
  }
}

resource "aws_s3_bucket_lifecycle_configuration" "state" {
  bucket = local.bucket_id

  rule {
    id     = "keep-90-days-of-history"
    status = "Enabled"

    filter {}

    noncurrent_version_expiration {
      noncurrent_days = 90
    }
  }

  depends_on = [aws_s3_bucket_versioning.state]
}

data "aws_iam_policy_document" "state" {
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
}

resource "aws_s3_bucket_policy" "state" {
  bucket = local.bucket_id
  policy = data.aws_iam_policy_document.state.json

  depends_on = [aws_s3_bucket_public_access_block.state]
}
