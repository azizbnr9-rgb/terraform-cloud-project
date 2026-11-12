variable "name_prefix" {
  description = "Préfixe de nommage des ressources (<projet>-<environnement>)."
  type        = string
}

variable "environment" {
  description = "Nom de l'environnement (affiché sur la page de démonstration)."
  type        = string
}

variable "instance_type" {
  description = "Type d'instance EC2."
  type        = string
  default     = "t3.micro"

  validation {
    condition     = can(regex("^[a-z][a-z0-9]*\\.[a-z0-9]+$", var.instance_type))
    error_message = "instance_type doit être un type EC2 valide (ex : t3.micro)."
  }
}

variable "ami_ssm_parameter" {
  description = "Paramètre SSM public donnant l'AMI la plus récente (Amazon Linux 2023 par défaut)."
  type        = string
  default     = "/aws/service/ami-amazon-linux-latest/al2023-ami-kernel-default-x86_64"
}

variable "app_subnet_ids" {
  description = "Sous-réseaux privés applicatifs (au moins deux AZ)."
  type        = list(string)

  validation {
    condition     = length(var.app_subnet_ids) >= 2
    error_message = "L'Auto Scaling Group doit couvrir au moins deux sous-réseaux (deux AZ)."
  }
}

variable "app_sg_id" {
  description = "Security Group des instances applicatives."
  type        = string
}

variable "instance_profile_name" {
  description = "Profil d'instance IAM attaché aux EC2."
  type        = string
}

variable "target_group_arn" {
  description = "Target Group de l'ALB dans lequel enregistrer les instances."
  type        = string
}

variable "app_port" {
  description = "Port d'écoute du serveur web."
  type        = number
  default     = 80
}

variable "min_size" {
  description = "Nombre minimal d'instances."
  type        = number
  default     = 2

  validation {
    condition     = var.min_size >= 1
    error_message = "min_size doit être au moins 1."
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

variable "cpu_target_value" {
  description = "Cible d'utilisation CPU moyenne (%) pour la politique de scaling."
  type        = number
  default     = 50

  validation {
    condition     = var.cpu_target_value > 10 && var.cpu_target_value < 95
    error_message = "cpu_target_value doit être compris entre 10 et 95."
  }
}

variable "root_volume_size" {
  description = "Taille du volume racine (Gio)."
  type        = number
  default     = 8
}

variable "detailed_monitoring" {
  description = "Active la supervision CloudWatch détaillée (1 min, payante)."
  type        = bool
  default     = false
}

variable "tags" {
  description = "Tags appliqués aux ressources du module."
  type        = map(string)
  default     = {}
}

variable "db_address" {
  description = "Nom d'hote prive de la base RDS PostgreSQL."
  type        = string
  default     = ""
}

variable "db_name" {
  description = "Nom de la base de donnees."
  type        = string
  default     = "appdb"
}

variable "db_port" {
  description = "Port d'ecoute de la base RDS."
  type        = number
  default     = 5432
}

variable "db_secret_arn" {
  description = "ARN du secret Secrets Manager pour les identifiants administrateur RDS."
  type        = string
  default     = ""
}

variable "s3_bucket_name" {
  description = "Nom du bucket S3 applicatif pour les assets et journaux."
  type        = string
  default     = ""
}
