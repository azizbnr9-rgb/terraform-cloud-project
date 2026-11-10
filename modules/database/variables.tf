variable "name_prefix" {
  description = "Préfixe de nommage des ressources (<projet>-<environnement>)."
  type        = string
}

variable "db_subnet_ids" {
  description = "Sous-réseaux privés dédiés à la base (au moins deux AZ)."
  type        = list(string)

  validation {
    condition     = length(var.db_subnet_ids) >= 2
    error_message = "Un DB subnet group RDS exige au moins deux sous-réseaux dans deux AZ."
  }
}

variable "db_sg_id" {
  description = "Security Group de la base de données."
  type        = string
}

variable "engine_major_version" {
  description = "Version majeure de PostgreSQL."
  type        = string
  default     = "16"

  validation {
    condition     = contains(["15", "16", "17"], var.engine_major_version)
    error_message = "engine_major_version doit être 15, 16 ou 17."
  }
}

variable "db_instance_class" {
  description = "Classe d'instance RDS."
  type        = string
  default     = "db.t3.micro"

  validation {
    condition     = startswith(var.db_instance_class, "db.")
    error_message = "db_instance_class doit commencer par « db. » (ex : db.t3.micro)."
  }
}

variable "db_name" {
  description = "Nom de la base créée initialement."
  type        = string
  default     = "appdb"

  validation {
    condition     = can(regex("^[a-zA-Z][a-zA-Z0-9_]{0,62}$", var.db_name))
    error_message = "db_name doit commencer par une lettre et ne contenir que lettres, chiffres et _."
  }
}

variable "db_username" {
  description = "Nom de l'utilisateur administrateur (le mot de passe est géré par Secrets Manager)."
  type        = string
  default     = "dbadmin"

  validation {
    condition     = !contains(["admin", "postgres", "rdsadmin"], var.db_username)
    error_message = "Ce nom d'utilisateur est réservé ; choisissez-en un autre."
  }
}

variable "db_port" {
  description = "Port d'écoute de la base."
  type        = number
  default     = 5432
}

variable "allocated_storage" {
  description = "Stockage initial (Gio)."
  type        = number
  default     = 20

  validation {
    condition     = var.allocated_storage >= 20
    error_message = "RDS gp3 exige au moins 20 Gio."
  }
}

variable "max_allocated_storage" {
  description = "Plafond d'auto-extension du stockage (Gio)."
  type        = number
  default     = 50
}

variable "multi_az" {
  description = "Déploie une instance de secours synchrone dans une seconde AZ (recommandé en prod)."
  type        = bool
  default     = false
}

variable "backup_retention_days" {
  description = "Durée de rétention des sauvegardes automatiques (jours)."
  type        = number
  default     = 1

  validation {
    condition     = var.backup_retention_days >= 0 && var.backup_retention_days <= 35
    error_message = "backup_retention_days doit être compris entre 0 et 35."
  }
}

variable "deletion_protection" {
  description = "Protection contre la suppression de l'instance RDS."
  type        = bool
  default     = false
}

variable "skip_final_snapshot" {
  description = "Ne pas créer de snapshot final lors de la destruction (true en dev/test)."
  type        = bool
  default     = true
}

variable "tags" {
  description = "Tags appliqués aux ressources du module."
  type        = map(string)
  default     = {}
}
