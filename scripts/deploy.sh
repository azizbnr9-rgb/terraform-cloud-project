#!/usr/bin/env bash
# Déploiement complet d'un environnement (bootstrap du backend si nécessaire).
#   Usage : ./scripts/deploy.sh <dev|test|prod> [plan|apply|destroy]
# Prérequis : Terraform >= 1.10, AWS CLI v2, identifiants AWS dans l'environnement
#             (AWS CloudShell, aws sso login, ou variables AWS_* — jamais dans Git).
set -euo pipefail

ENV="${1:?Usage: $0 <dev|test|prod> [plan|apply|destroy]}"
ACTION="${2:-apply}"
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
REGION="${AWS_REGION:-us-east-1}"

[[ "$ENV" =~ ^(dev|test|prod)$ ]] || { echo "Environnement invalide : $ENV" >&2; exit 1; }

echo "==> Identité AWS"
aws sts get-caller-identity --output table

# --- 1. Bootstrap du backend (une seule fois) -------------------------------
ACCOUNT="$(aws sts get-caller-identity --query Account --output text)"
BUCKET="cloud5-tfstate-${ACCOUNT}-${REGION}"
if ! aws s3api head-bucket --bucket "$BUCKET" 2>/dev/null; then
  echo "==> Bootstrap : création du bucket d'état $BUCKET"
  terraform -chdir="$ROOT/bootstrap" init -input=false
  terraform -chdir="$ROOT/bootstrap" apply -input=false -auto-approve -var="aws_region=$REGION"
fi

# --- 2. Projet principal ----------------------------------------------------
DIR="$ROOT/environments/$ENV"
terraform fmt -check -recursive "$ROOT"
terraform -chdir="$DIR" init -input=false -reconfigure \
  -backend-config="bucket=$BUCKET" -backend-config="region=$REGION"
terraform -chdir="$DIR" validate

case "$ACTION" in
  plan)
    terraform -chdir="$DIR" plan -input=false -out=tfplan
    terraform -chdir="$DIR" show -no-color tfplan > "$DIR/plan.txt"
    echo "Plan lisible : $DIR/plan.txt" ;;
  apply)
    terraform -chdir="$DIR" plan -input=false -out=tfplan
    terraform -chdir="$DIR" show -no-color tfplan > "$DIR/plan.txt"
    [[ "$ENV" == "dev" ]] || read -rp "Appliquer le plan sur $ENV ? (oui/non) " ok && [[ "${ok:-oui}" == "oui" ]]
    terraform -chdir="$DIR" apply -input=false tfplan
    terraform -chdir="$DIR" output ;;
  destroy)
    terraform -chdir="$DIR" destroy -input=false ;;
  *) echo "Action inconnue : $ACTION" >&2; exit 1 ;;
esac
