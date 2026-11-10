variable "name_prefix" {
  description = "Préfixe de nommage des ressources (<projet>-<environnement>)."
  type        = string
}

variable "vpc_id" {
  description = "Identifiant du VPC dans lequel créer les Security Groups."
  type        = string
}

variable "app_port" {
  description = "Port d'écoute de l'application sur les instances."
  type        = number
  default     = 80

  validation {
    condition     = var.app_port > 0 && var.app_port < 65536
    error_message = "app_port doit être compris entre 1 et 65535."
  }
}

variable "db_port" {
  description = "Port de la base de données (5432 pour PostgreSQL)."
  type        = number
  default     = 5432

  validation {
    condition     = var.db_port > 0 && var.db_port < 65536
    error_message = "db_port doit être compris entre 1 et 65535."
  }
}

variable "allowed_web_cidrs" {
  description = "CIDR autorisés à joindre l'ALB en HTTP/HTTPS."
  type        = list(string)
  default     = ["0.0.0.0/0"]

  validation {
    condition     = alltrue([for c in var.allowed_web_cidrs : can(cidrhost(c, 0))])
    error_message = "Chaque entrée de allowed_web_cidrs doit être un CIDR IPv4 valide."
  }
}

variable "enable_https" {
  description = "Ouvre le port 443 sur l'ALB (nécessite un certificat ACM côté load-balancer)."
  type        = bool
  default     = false
}

variable "assets_bucket_arn" {
  description = "ARN du bucket S3 applicatif (lecture seule du préfixe assets/ par les instances)."
  type        = string
}

variable "create_iam_role" {
  description = "Crée le rôle et le profil IAM des EC2. false si la création IAM est interdite (Learner Lab)."
  type        = bool
  default     = true
}

variable "existing_instance_profile_name" {
  description = "Profil d'instance existant utilisé quand create_iam_role = false (ex : LabInstanceProfile)."
  type        = string
  default     = "LabInstanceProfile"
}

variable "tags" {
  description = "Tags appliqués aux ressources du module."
  type        = map(string)
  default     = {}
}
