# Environnement DEV : dimensionnement minimal, déploiement automatique depuis main.
# Aucune valeur sensible ici (le mot de passe RDS est géré par Secrets Manager).
aws_region   = "us-east-1"
project_name = "cloud5"
environment  = "dev"
owner        = "equipe-cloud5"

vpc_cidr           = "10.20.0.0/16"
az_count           = 2
single_nat_gateway = true

# AWS Academy Learner Lab : création IAM interdite -> profil fourni par le lab.
# Sur un compte AWS standard : create_iam_role = true
create_iam_role                = false
existing_instance_profile_name = "LabInstanceProfile"
create_buckets_with_cli        = true # SCP Learner Lab sur s3:GetBucketObjectLockConfiguration

instance_type    = "t3.micro"
min_size         = 2
max_size         = 4
desired_capacity = 2

db_instance_class        = "db.t3.micro"
db_multi_az              = false
db_backup_retention_days = 1
db_deletion_protection   = false
db_skip_final_snapshot   = true

force_destroy_storage   = true
alb_deletion_protection = false
log_retention_days      = 31
