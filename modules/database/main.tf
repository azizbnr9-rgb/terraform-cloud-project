resource "aws_db_subnet_group" "this" {
  name        = "${var.name_prefix}-db-subnets"
  description = "Sous-réseaux privés de la base ${var.name_prefix}"
  subnet_ids  = var.db_subnet_ids

  tags = merge(var.tags, { Name = "${var.name_prefix}-db-subnets" })
}

resource "aws_db_parameter_group" "this" {
  name        = "${var.name_prefix}-pg${var.engine_major_version}"
  family      = "postgres${var.engine_major_version}"
  description = "Paramètres PostgreSQL ${var.name_prefix}"

  # Chiffrement TLS obligatoire pour les connexions clientes
  parameter {
    name  = "rds.force_ssl"
    value = "1"
  }

  parameter {
    name  = "log_connections"
    value = "1"
  }

  tags = var.tags
}

resource "aws_db_instance" "this" {
  identifier     = "${var.name_prefix}-db"
  engine         = "postgres"
  engine_version = var.engine_major_version
  instance_class = var.db_instance_class

  db_name  = var.db_name
  username = var.db_username
  port     = var.db_port

  # Mot de passe généré et stocké par RDS dans AWS Secrets Manager :
  # aucun secret dans Git, dans les tfvars ni dans l'état Terraform.
  manage_master_user_password = true

  allocated_storage     = var.allocated_storage
  max_allocated_storage = var.max_allocated_storage
  storage_type          = "gp3"
  storage_encrypted     = true

  db_subnet_group_name   = aws_db_subnet_group.this.name
  vpc_security_group_ids = [var.db_sg_id]
  parameter_group_name   = aws_db_parameter_group.this.name
  publicly_accessible    = false
  multi_az               = var.multi_az

  backup_retention_period    = var.backup_retention_days
  backup_window              = "02:00-03:00"
  maintenance_window         = "sun:03:30-sun:04:30"
  auto_minor_version_upgrade = true
  copy_tags_to_snapshot      = true

  deletion_protection       = var.deletion_protection
  skip_final_snapshot       = var.skip_final_snapshot
  final_snapshot_identifier = var.skip_final_snapshot ? null : "${var.name_prefix}-db-final"

  tags = merge(var.tags, { Name = "${var.name_prefix}-db" })
}
