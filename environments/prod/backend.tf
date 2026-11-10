# Backend distant S3 : état chiffré, versionné et verrouillé (fichier .tflock natif).
# Le nom du bucket n'est pas codé en dur : il est fourni à l'initialisation
#   terraform init -backend-config="bucket=<bucket créé par bootstrap/>" -backend-config="region=<region>"
terraform {
  backend "s3" {
    key          = "prod/terraform.tfstate"
    encrypt      = true
    use_lockfile = true
  }
}
