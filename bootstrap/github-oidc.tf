# ---------------------------------------------------------------------------
# Identité fédérée GitHub Actions (OIDC) — recommandé sur un compte AWS standard.
# Désactivé par défaut : AWS Academy Learner Lab interdit la création IAM ;
# le pipeline utilise alors les secrets GitHub (solution de repli du cahier des charges).
#
# Deux rôles pour respecter le moindre privilège :
#   - plan  : lecture seule + accès à l'état (Pull Requests)
#   - apply : déploiement, limité aux GitHub Environments dev/test/prod
# ---------------------------------------------------------------------------
locals {
  oidc_enabled = var.create_github_oidc ? 1 : 0
  repo         = "${var.github_owner}/${var.github_repo}"
}

resource "aws_iam_openid_connect_provider" "github" {
  count = local.oidc_enabled

  url            = "https://token.actions.githubusercontent.com"
  client_id_list = ["sts.amazonaws.com"]

  # AWS valide désormais le certificat GitHub lui-même ; valeur publique documentée par GitHub
  thumbprint_list = ["6938fd4d98bab03faadb97b34396831e3780aea1"]
}

data "aws_iam_policy_document" "assume_plan" {
  count = local.oidc_enabled

  statement {
    actions = ["sts:AssumeRoleWithWebIdentity"]

    principals {
      type        = "Federated"
      identifiers = [aws_iam_openid_connect_provider.github[0].arn]
    }

    condition {
      test     = "StringEquals"
      variable = "token.actions.githubusercontent.com:aud"
      values   = ["sts.amazonaws.com"]
    }

    condition {
      test     = "StringLike"
      variable = "token.actions.githubusercontent.com:sub"
      values = [
        "repo:${local.repo}:pull_request",
        "repo:${local.repo}:ref:refs/heads/main",
      ]
    }
  }
}

data "aws_iam_policy_document" "assume_apply" {
  count = local.oidc_enabled

  statement {
    actions = ["sts:AssumeRoleWithWebIdentity"]

    principals {
      type        = "Federated"
      identifiers = [aws_iam_openid_connect_provider.github[0].arn]
    }

    condition {
      test     = "StringEquals"
      variable = "token.actions.githubusercontent.com:aud"
      values   = ["sts.amazonaws.com"]
    }

    # Seuls les jobs rattachés à un GitHub Environment protégé peuvent déployer
    condition {
      test     = "StringLike"
      variable = "token.actions.githubusercontent.com:sub"
      values   = [for e in ["dev", "test", "prod"] : "repo:${local.repo}:environment:${e}"]
    }
  }
}

data "aws_iam_policy_document" "state_access" {
  statement {
    sid       = "StateBucketList"
    actions   = ["s3:ListBucket"]
    resources = [aws_s3_bucket.state.arn]
  }

  statement {
    sid       = "StateObjects"
    actions   = ["s3:GetObject", "s3:PutObject", "s3:DeleteObject"]
    resources = ["${aws_s3_bucket.state.arn}/*"]
  }
}

data "aws_iam_policy_document" "deploy" {
  statement {
    sid = "ProjectServices"
    actions = [
      "ec2:*",
      "elasticloadbalancing:*",
      "autoscaling:*",
      "rds:*",
      "s3:*",
      "ssm:GetParameter",
      "ssm:GetParameters",
      "secretsmanager:DescribeSecret",
      "kms:DescribeKey",
      "cloudwatch:*",
      "application-autoscaling:*",
    ]
    resources = ["*"]
  }

  # IAM limité aux rôles/profils préfixés par le nom du projet
  statement {
    sid = "ProjectIam"
    actions = [
      "iam:*Role*",
      "iam:*InstanceProfile*",
      "iam:PassRole",
      "iam:CreateServiceLinkedRole",
    ]
    resources = [
      "arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/${var.project_name}-*",
      "arn:aws:iam::${data.aws_caller_identity.current.account_id}:instance-profile/${var.project_name}-*",
      "arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/aws-service-role/*",
    ]
  }
}

resource "aws_iam_role" "plan" {
  count = local.oidc_enabled

  name               = "${var.project_name}-github-plan"
  assume_role_policy = data.aws_iam_policy_document.assume_plan[0].json
}

resource "aws_iam_role_policy_attachment" "plan_readonly" {
  count = local.oidc_enabled

  role       = aws_iam_role.plan[0].name
  policy_arn = "arn:aws:iam::aws:policy/ReadOnlyAccess"
}

resource "aws_iam_role_policy" "plan_state" {
  count = local.oidc_enabled

  name   = "terraform-state"
  role   = aws_iam_role.plan[0].id
  policy = data.aws_iam_policy_document.state_access.json
}

resource "aws_iam_role" "apply" {
  count = local.oidc_enabled

  name               = "${var.project_name}-github-apply"
  assume_role_policy = data.aws_iam_policy_document.assume_apply[0].json
}

resource "aws_iam_role_policy" "apply_deploy" {
  count = local.oidc_enabled

  name   = "deploy"
  role   = aws_iam_role.apply[0].id
  policy = data.aws_iam_policy_document.deploy.json
}

resource "aws_iam_role_policy" "apply_state" {
  count = local.oidc_enabled

  name   = "terraform-state"
  role   = aws_iam_role.apply[0].id
  policy = data.aws_iam_policy_document.state_access.json
}
