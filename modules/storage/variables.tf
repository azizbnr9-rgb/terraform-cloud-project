variable "name_prefix" {
  description = "Préfixe de nommage des ressources (<projet>-<environnement>)."
  type        = string
}

variable "force_destroy" {
  description = "Autorise la suppression du bucket même non vide (true en dev/test pour terraform destroy)."
  type        = bool
  default     = false
}

variable "log_retention_days" {
  description = "Durée de conservation des journaux ALB (jours)."
  type        = number
  default     = 90

  validation {
    condition     = var.log_retention_days >= 31
    error_message = "log_retention_days doit être supérieur à 30 (transition STANDARD_IA à 30 jours)."
  }
}

variable "noncurrent_version_days" {
  description = "Durée de conservation des versions non courantes (jours)."
  type        = number
  default     = 30

  validation {
    condition     = var.noncurrent_version_days >= 1
    error_message = "noncurrent_version_days doit être au moins 1."
  }
}

variable "tags" {
  description = "Tags appliqués aux ressources du module."
  type        = map(string)
  default     = {}
}
