data "aws_availability_zones" "available" {
  state = "available"
}

locals {
  name_prefix = "${var.project_name}-${var.environment}"
  azs         = slice(data.aws_availability_zones.available.names, 0, var.az_count)

  common_tags = {
    Project     = var.project_name
    Environment = var.environment
    ManagedBy   = "Terraform"
    Owner       = var.owner
  }

  # Plan d'adressage dérivé du CIDR du VPC (10.20.0.0/16 -> .1/.2, .11/.12, .21/.22)
  public_subnet_cidrs = [for i in range(var.az_count) : cidrsubnet(var.vpc_cidr, 8, 1 + i)]
  app_subnet_cidrs    = [for i in range(var.az_count) : cidrsubnet(var.vpc_cidr, 8, 11 + i)]
  db_subnet_cidrs     = [for i in range(var.az_count) : cidrsubnet(var.vpc_cidr, 8, 21 + i)]
}

module "network" {
  source = "../../modules/network"

  name_prefix         = local.name_prefix
  vpc_cidr            = var.vpc_cidr
  azs                 = local.azs
  public_subnet_cidrs = local.public_subnet_cidrs
  app_subnet_cidrs    = local.app_subnet_cidrs
  db_subnet_cidrs     = local.db_subnet_cidrs
  single_nat_gateway  = var.single_nat_gateway
}

module "storage" {
  source = "../../modules/storage"

  name_prefix        = local.name_prefix
  force_destroy      = var.force_destroy_storage
  log_retention_days = var.log_retention_days
}

module "security" {
  source = "../../modules/security"

  name_prefix       = local.name_prefix
  vpc_id            = module.network.vpc_id
  app_port          = var.app_port
  db_port           = var.db_port
  allowed_web_cidrs = var.allowed_web_cidrs
  enable_https      = var.certificate_arn != null
  assets_bucket_arn = module.storage.bucket_arn

  create_iam_role                = var.create_iam_role
  existing_instance_profile_name = var.existing_instance_profile_name
}

module "load_balancer" {
  source = "../../modules/load-balancer"

  name_prefix         = local.name_prefix
  vpc_id              = module.network.vpc_id
  public_subnet_ids   = module.network.public_subnet_ids
  alb_sg_id           = module.security.alb_sg_id
  app_port            = var.app_port
  certificate_arn     = var.certificate_arn
  access_logs_bucket  = var.enable_alb_access_logs ? module.storage.bucket_name : null
  deletion_protection = var.alb_deletion_protection
}

module "compute" {
  source = "../../modules/compute"

  name_prefix           = local.name_prefix
  environment           = var.environment
  instance_type         = var.instance_type
  app_subnet_ids        = module.network.app_subnet_ids
  app_sg_id             = module.security.app_sg_id
  instance_profile_name = module.security.instance_profile_name
  target_group_arn      = module.load_balancer.target_group_arn
  app_port              = var.app_port
  min_size              = var.min_size
  max_size              = var.max_size
  desired_capacity      = var.desired_capacity
}

module "database" {
  source = "../../modules/database"

  name_prefix           = local.name_prefix
  db_subnet_ids         = module.network.db_subnet_ids
  db_sg_id              = module.security.db_sg_id
  db_instance_class     = var.db_instance_class
  db_port               = var.db_port
  multi_az              = var.db_multi_az
  backup_retention_days = var.db_backup_retention_days
  deletion_protection   = var.db_deletion_protection
  skip_final_snapshot   = var.db_skip_final_snapshot
}
