variable "name_prefix" {
  description = "Préfixe de nommage des ressources (<projet>-<environnement>)."
  type        = string
}

variable "vpc_cidr" {
  description = "Bloc CIDR principal du VPC."
  type        = string

  validation {
    condition     = can(cidrhost(var.vpc_cidr, 0))
    error_message = "vpc_cidr doit être un bloc CIDR IPv4 valide (ex : 10.20.0.0/16)."
  }
}

variable "azs" {
  description = "Zones de disponibilité utilisées (au moins deux)."
  type        = list(string)

  validation {
    condition     = length(var.azs) >= 2
    error_message = "Au moins deux zones de disponibilité sont requises pour la haute disponibilité."
  }
}

variable "public_subnet_cidrs" {
  description = "CIDR des sous-réseaux publics (un par AZ, même ordre que azs)."
  type        = list(string)

  validation {
    condition     = alltrue([for c in var.public_subnet_cidrs : can(cidrhost(c, 0))])
    error_message = "Chaque CIDR public doit être valide."
  }
}

variable "app_subnet_cidrs" {
  description = "CIDR des sous-réseaux privés applicatifs (un par AZ)."
  type        = list(string)

  validation {
    condition     = alltrue([for c in var.app_subnet_cidrs : can(cidrhost(c, 0))])
    error_message = "Chaque CIDR applicatif doit être valide."
  }
}

variable "db_subnet_cidrs" {
  description = "CIDR des sous-réseaux privés base de données (un par AZ)."
  type        = list(string)

  validation {
    condition     = alltrue([for c in var.db_subnet_cidrs : can(cidrhost(c, 0))])
    error_message = "Chaque CIDR base de données doit être valide."
  }
}

variable "single_nat_gateway" {
  description = "true : une seule NAT Gateway (économique). false : une NAT par AZ (haute disponibilité)."
  type        = bool
  default     = true
}

variable "tags" {
  description = "Tags appliqués aux ressources du module."
  type        = map(string)
  default     = {}
}
