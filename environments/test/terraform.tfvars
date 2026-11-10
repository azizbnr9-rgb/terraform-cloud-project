# Environnement TEST : proche de la prod mais réduit, déploiement après revue + approbation manuelle.
# À DÉTRUIRE dès la fin de la démonstration (terraform destroy).
aws_region   = "us-east-1"
project_name = "cloud5"
environment  = "test"
owner        = "equipe-cloud5"

vpc_cidr           = "10.30.0.0/16"
az_count           = 2
single_nat_gateway = true

create_iam_role                = false
existing_instance_profile_name = "LabInstanceProfile"
create_buckets_with_cli        = true # SCP Learner Lab sur s3:GetBucketObjectLockConfiguration

instance_type    = "t3.micro"
min_size         = 2
max_size         = 4
desired_capacity = 2

db_instance_class        = "db.t3.micro"
db_multi_az              = false
db_backup_retention_days = 3
db_deletion_protection   = false
db_skip_final_snapshot   = true

force_destroy_storage   = true
alb_deletion_protection = false
log_retention_days      = 31
