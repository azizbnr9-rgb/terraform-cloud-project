variable "name_prefix" {
  description = "Préfixe de nommage des ressources (<projet>-<environnement>)."
  type        = string

  validation {
    condition     = length(var.name_prefix) <= 26
    error_message = "name_prefix doit faire 26 caractères maximum (limite de 32 pour les noms d'ALB/Target Group)."
  }
}

variable "vpc_id" {
  description = "Identifiant du VPC."
  type        = string
}

variable "public_subnet_ids" {
  description = "Sous-réseaux publics de l'ALB (au moins deux AZ)."
  type        = list(string)

  validation {
    condition     = length(var.public_subnet_ids) >= 2
    error_message = "L'ALB doit être placé dans au moins deux sous-réseaux publics."
  }
}

variable "alb_sg_id" {
  description = "Security Group de l'ALB."
  type        = string
}

variable "app_port" {
  description = "Port des instances ciblées."
  type        = number
  default     = 80
}

variable "health_check_path" {
  description = "Chemin HTTP utilisé par le health check du Target Group."
  type        = string
  default     = "/health"

  validation {
    condition     = startswith(var.health_check_path, "/")
    error_message = "health_check_path doit commencer par « / »."
  }
}

variable "certificate_arn" {
  description = "ARN d'un certificat ACM pour activer HTTPS (null = HTTP seul)."
  type        = string
  default     = null
}

variable "access_logs_bucket" {
  description = "Nom du bucket S3 recevant les journaux d'accès de l'ALB (null = désactivé)."
  type        = string
  default     = null
}

variable "deletion_protection" {
  description = "Protection contre la suppression de l'ALB (recommandé en prod)."
  type        = bool
  default     = false
}

variable "tags" {
  description = "Tags appliqués aux ressources du module."
  type        = map(string)
  default     = {}
}
