data "aws_partition" "current" {}

# ---------------------------------------------------------------------------
# Security Groups (chaînés : Internet -> ALB -> App -> DB)
# ---------------------------------------------------------------------------
resource "aws_security_group" "alb" {
  name        = "${var.name_prefix}-sg-alb"
  description = "ALB : HTTP/HTTPS depuis Internet"
  vpc_id      = var.vpc_id

  tags = merge(var.tags, { Name = "${var.name_prefix}-sg-alb" })
}

resource "aws_security_group" "app" {
  name        = "${var.name_prefix}-sg-app"
  description = "Instances applicatives - trafic web uniquement depuis le SG ALB"
  vpc_id      = var.vpc_id

  tags = merge(var.tags, { Name = "${var.name_prefix}-sg-app" })
}

resource "aws_security_group" "db" {
  name        = "${var.name_prefix}-sg-db"
  description = "RDS : connexions uniquement depuis le SG applicatif"
  vpc_id      = var.vpc_id

  tags = merge(var.tags, { Name = "${var.name_prefix}-sg-db" })
}

# --- ALB -------------------------------------------------------------------
resource "aws_vpc_security_group_ingress_rule" "alb_http" {
  for_each = toset(var.allowed_web_cidrs)

  security_group_id = aws_security_group.alb.id
  description       = "HTTP depuis Internet"
  ip_protocol       = "tcp"
  from_port         = 80
  to_port           = 80
  cidr_ipv4         = each.value
}

resource "aws_vpc_security_group_ingress_rule" "alb_https" {
  for_each = var.enable_https ? toset(var.allowed_web_cidrs) : toset([])

  security_group_id = aws_security_group.alb.id
  description       = "HTTPS depuis Internet"
  ip_protocol       = "tcp"
  from_port         = 443
  to_port           = 443
  cidr_ipv4         = each.value
}

resource "aws_vpc_security_group_egress_rule" "alb_to_app" {
  security_group_id            = aws_security_group.alb.id
  description                  = "Vers les instances applicatives uniquement"
  ip_protocol                  = "tcp"
  from_port                    = var.app_port
  to_port                      = var.app_port
  referenced_security_group_id = aws_security_group.app.id
}

# --- APP -------------------------------------------------------------------
resource "aws_vpc_security_group_ingress_rule" "app_from_alb" {
  security_group_id            = aws_security_group.app.id
  description                  = "Trafic web depuis le SG ALB uniquement"
  ip_protocol                  = "tcp"
  from_port                    = var.app_port
  to_port                      = var.app_port
  referenced_security_group_id = aws_security_group.alb.id
}

# Sortie HTTPS/HTTP (via NAT) : dépôts de paquets et points de terminaison SSM
resource "aws_vpc_security_group_egress_rule" "app_https_out" {
  security_group_id = aws_security_group.app.id
  description       = "HTTPS sortant (paquets, SSM) via NAT"
  ip_protocol       = "tcp"
  from_port         = 443
  to_port           = 443
  cidr_ipv4         = "0.0.0.0/0"
}

resource "aws_vpc_security_group_egress_rule" "app_http_out" {
  security_group_id = aws_security_group.app.id
  description       = "HTTP sortant (miroirs de paquets) via NAT"
  ip_protocol       = "tcp"
  from_port         = 80
  to_port           = 80
  cidr_ipv4         = "0.0.0.0/0"
}

resource "aws_vpc_security_group_egress_rule" "app_to_db" {
  security_group_id            = aws_security_group.app.id
  description                  = "Vers la base de donnees"
  ip_protocol                  = "tcp"
  from_port                    = var.db_port
  to_port                      = var.db_port
  referenced_security_group_id = aws_security_group.db.id
}

# --- DB --------------------------------------------------------------------
resource "aws_vpc_security_group_ingress_rule" "db_from_app" {
  security_group_id            = aws_security_group.db.id
  description                  = "Connexions depuis le SG applicatif uniquement"
  ip_protocol                  = "tcp"
  from_port                    = var.db_port
  to_port                      = var.db_port
  referenced_security_group_id = aws_security_group.app.id
}
# Aucune règle de sortie sur le SG DB : RDS n'initie aucune connexion.

# ---------------------------------------------------------------------------
# IAM : rôle des instances EC2 (moindre privilège)
#   create_iam_role = false : comptes où la création IAM est interdite
#   (AWS Academy Learner Lab) -> réutilisation d'un profil existant.
#   - Accès administratif via SSM Session Manager (pas de SSH, pas de port 22)
#   - Lecture seule sur le préfixe "assets/" du bucket applicatif
# ---------------------------------------------------------------------------
data "aws_iam_policy_document" "ec2_assume" {
  statement {
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["ec2.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "ec2" {
  count = var.create_iam_role ? 1 : 0

  name               = "${var.name_prefix}-role-ec2"
  description        = "Role des instances applicatives ${var.name_prefix}"
  assume_role_policy = data.aws_iam_policy_document.ec2_assume.json

  tags = var.tags
}

resource "aws_iam_role_policy_attachment" "ssm_core" {
  count = var.create_iam_role ? 1 : 0

  role       = aws_iam_role.ec2[0].name
  policy_arn = "arn:${data.aws_partition.current.partition}:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

data "aws_iam_policy_document" "assets_read" {
  statement {
    sid       = "ListAssetsPrefix"
    actions   = ["s3:ListBucket"]
    resources = [var.assets_bucket_arn]

    condition {
      test     = "StringLike"
      variable = "s3:prefix"
      values   = ["assets/*"]
    }
  }

  statement {
    sid       = "ReadAssets"
    actions   = ["s3:GetObject"]
    resources = ["${var.assets_bucket_arn}/assets/*"]
  }
}

resource "aws_iam_role_policy" "assets_read" {
  count = var.create_iam_role ? 1 : 0

  name   = "${var.name_prefix}-assets-read"
  role   = aws_iam_role.ec2[0].id
  policy = data.aws_iam_policy_document.assets_read.json
}

resource "aws_iam_instance_profile" "ec2" {
  count = var.create_iam_role ? 1 : 0

  name = "${var.name_prefix}-profile-ec2"
  role = aws_iam_role.ec2[0].name

  tags = var.tags
}
