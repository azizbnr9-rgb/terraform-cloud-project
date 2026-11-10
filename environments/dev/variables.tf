# ---------------------------------------------------------------------------
# Général
# ---------------------------------------------------------------------------
variable "aws_region" {
  description = "Région AWS de déploiement."
  type        = string
  default     = "eu-west-3"

  validation {
    condition     = can(regex("^[a-z]{2}-[a-z]+-[0-9]$", var.aws_region))
    error_message = "aws_region doit être un identifiant de région AWS (ex : eu-west-3)."
  }
}

variable "project_name" {
  description = "Préfixe de nommage du projet."
  type        = string
  default     = "cloud5"

  validation {
    condition     = can(regex("^[a-z][a-z0-9-]{1,14}$", var.project_name))
    error_message = "project_name : 2 à 15 caractères, minuscules, chiffres et tirets."
  }
}

variable "environment" {
  description = "Nom de l'environnement."
  type        = string

  validation {
    condition     = contains(["dev", "test", "prod"], var.environment)
    error_message = "environment doit valoir dev, test ou prod."
  }
}

variable "owner" {
  description = "Équipe ou personne responsable (tag Owner)."
  type        = string
}

# ---------------------------------------------------------------------------
# Réseau
# ---------------------------------------------------------------------------
variable "vpc_cidr" {
  description = "Bloc réseau principal (/16 attendu : les sous-réseaux sont des /24 dérivés)."
  type        = string
  default     = "10.20.0.0/16"

  validation {
    condition     = can(cidrhost(var.vpc_cidr, 0)) && endswith(var.vpc_cidr, "/16")
    error_message = "vpc_cidr doit être un CIDR IPv4 valide en /16."
  }
}

variable "az_count" {
  description = "Nombre de zones de disponibilité utilisées."
  type        = number
  default     = 2

  validation {
    condition     = var.az_count >= 2 && var.az_count <= 3
    error_message = "az_count doit valoir 2 ou 3."
  }
}

variable "single_nat_gateway" {
  description = "Une seule NAT Gateway (économique) au lieu d'une par AZ."
  type        = bool
  default     = true
}

variable "allowed_web_cidrs" {
  description = "Origines autorisées vers l'ALB."
  type        = list(string)
  default     = ["0.0.0.0/0"]
}

variable "create_iam_role" {
  description = "Crée le rôle IAM des EC2 (false sur AWS Academy Learner Lab, où IAM est verrouillé)."
  type        = bool
  default     = true
}

variable "existing_instance_profile_name" {
  description = "Profil d'instance existant si create_iam_role = false."
  type        = string
  default     = "LabInstanceProfile"
}

# ---------------------------------------------------------------------------
# Application
# ---------------------------------------------------------------------------
variable "app_port" {
  description = "Port d'écoute de l'application."
  type        = number
  default     = 80
}

variable "instance_type" {
  description = "Type d'instance EC2."
  type        = string
  default     = "t3.micro"
}

variable "min_size" {
  description = "Nombre minimal d'instances."
  type        = number
  default     = 2

  validation {
    condition     = var.min_size >= 2
    error_message = "min_size doit être au moins 2 (une instance par AZ minimum)."
  }
}

variable "max_size" {
  description = "Nombre maximal d'instances."
  type        = number
  default     = 4
}

variable "desired_capacity" {
  description = "Capacité souhaitée initiale."
  type        = number
  default     = 2
}

variable "certificate_arn" {
  description = "Certificat ACM pour HTTPS (null = HTTP seul)."
  type        = string
  default     = null
}

variable "enable_alb_access_logs" {
  description = "Envoie les journaux d'accès de l'ALB dans le bucket S3."
  type        = bool
  default     = true
}

variable "alb_deletion_protection" {
  description = "Protection contre la suppression de l'ALB."
  type        = bool
  default     = false
}

# ---------------------------------------------------------------------------
# Base de données
# ---------------------------------------------------------------------------
variable "db_instance_class" {
  description = "Classe RDS."
  type        = string
  default     = "db.t3.micro"
}

variable "db_port" {
  description = "Port PostgreSQL."
  type        = number
  default     = 5432
}

variable "db_multi_az" {
  description = "RDS Multi-AZ."
  type        = bool
  default     = false
}

variable "db_backup_retention_days" {
  description = "Rétention des sauvegardes RDS (jours)."
  type        = number
  default     = 1
}

variable "db_deletion_protection" {
  description = "Protection contre la suppression de RDS."
  type        = bool
  default     = false
}

variable "db_skip_final_snapshot" {
  description = "Pas de snapshot final au destroy."
  type        = bool
  default     = true
}

# ---------------------------------------------------------------------------
# Stockage
# ---------------------------------------------------------------------------
variable "force_destroy_storage" {
  description = "Vide le bucket lors du destroy."
  type        = bool
  default     = true
}

variable "create_buckets_with_cli" {
  description = "Crée les buckets via l'AWS CLI (true sur AWS Academy Learner Lab, SCP S3)."
  type        = bool
  default     = false
}

variable "log_retention_days" {
  description = "Conservation des journaux ALB (jours)."
  type        = number
  default     = 90
}
