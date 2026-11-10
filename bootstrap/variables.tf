variable "aws_region" {
  description = "Région du bucket d'état."
  type        = string
  default     = "us-east-1"
}

variable "project_name" {
  description = "Préfixe du projet."
  type        = string
  default     = "cloud5"
}

variable "owner" {
  description = "Responsable (tag Owner)."
  type        = string
  default     = "equipe-cloud5"
}

variable "force_destroy" {
  description = "Autorise la suppression du bucket d'état non vide (fin de projet uniquement)."
  type        = bool
  default     = false
}

variable "create_github_oidc" {
  description = "Crée le fournisseur OIDC GitHub et les rôles plan/apply (impossible sur Learner Lab)."
  type        = bool
  default     = false
}

variable "github_owner" {
  description = "Propriétaire (utilisateur ou organisation) du dépôt GitHub."
  type        = string
  default     = "mon-compte"
}

variable "github_repo" {
  description = "Nom du dépôt GitHub."
  type        = string
  default     = "terraform-cloud-project"
}
