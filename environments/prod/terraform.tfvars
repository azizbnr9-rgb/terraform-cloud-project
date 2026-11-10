# Environnement PROD : haute disponibilité complète, validation manuelle obligatoire.
aws_region   = "us-east-1"
project_name = "cloud5"
environment  = "prod"
owner        = "equipe-cloud5"

vpc_cidr           = "10.40.0.0/16"
az_count           = 2
single_nat_gateway = false # une NAT Gateway par AZ

create_iam_role                = false
existing_instance_profile_name = "LabInstanceProfile"
create_buckets_with_cli        = true # SCP Learner Lab sur s3:GetBucketObjectLockConfiguration

instance_type    = "t3.small"
min_size         = 2
max_size         = 6
desired_capacity = 2

db_instance_class        = "db.t3.small"
db_multi_az              = true
db_backup_retention_days = 7
db_deletion_protection   = true
db_skip_final_snapshot   = false

force_destroy_storage   = false
alb_deletion_protection = true
log_retention_days      = 90

# certificate_arn = "arn:aws:acm:us-east-1:<compte>:certificate/<id>"  # active HTTPS
