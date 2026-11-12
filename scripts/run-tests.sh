#!/usr/bin/env bash
# Exécute les tests obligatoires (section 22 du cahier des charges) et journalise les résultats.
#   Usage : ./scripts/run-tests.sh <env>
# Résultats : docs/test-results-<env>.md
set -uo pipefail

ENV="${1:-dev}"
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
DIR="$ROOT/environments/$ENV"
OUT="$ROOT/docs/test-results-$ENV.md"
tf() { terraform -chdir="$DIR" "$@"; }

URL="$(tf output -raw alb_url)"
ASG="$(tf output -raw asg_name)"
DB_HOST="$(tf output -raw db_address)"

{
  echo "# Résultats des tests — $ENV"
  echo
  echo "Date : $(date -u '+%Y-%m-%d %H:%M UTC') — URL : $URL"
  echo
  echo "| Test | Procédure | Résultat attendu | Résultat obtenu | Statut |"
  echo "|------|-----------|------------------|-----------------|--------|"
} > "$OUT"

row() { echo "| $1 | \`$2\` | $3 | $4 | $5 |" >> "$OUT"; echo "[$5] $1 — $4"; }
ok() { [[ "$1" == "0" ]] && echo "✅ OK" || echo "❌ KO"; }

# 1. Format
terraform fmt -check -recursive "$ROOT" >/dev/null 2>&1; c=$?
row "Format" "terraform fmt -check -recursive" "Aucune différence" "code retour $c" "$(ok $c)"

# 2. Validation
v="$(tf validate -no-color 2>&1 | tr '\n' ' ')"; c=$?
row "Validation" "terraform validate" "Success" "${v:0:60}" "$(ok $c)"

# 3. Plan
p="$(tf plan -input=false -no-color -detailed-exitcode 2>&1 | grep -E '^(Plan:|No changes)' | head -1)"
row "Plan" "terraform plan" "Plan sans erreur" "${p:-voir journal}" "$( [[ -n "$p" ]] && echo '✅ OK' || echo '❌ KO')"

# 4. Accès Web
code="$(curl -s -o /dev/null -w '%{http_code}' --max-time 10 "$URL")"
row "Accès Web" "curl $URL" "HTTP 200" "HTTP $code" "$( [[ "$code" == "200" ]] && echo '✅ OK' || echo '❌ KO')"

# 5. Répartition de charge
hosts="$(for _ in $(seq 1 20); do curl -s --max-time 5 "$URL" | grep -o 'i-[0-9a-f]\{8,17\}' | head -1; done | sort -u)"
n="$(echo "$hosts" | grep -c . || true)"
row "Répartition" "20 requêtes sur l'ALB" "≥ 2 hôtes" "$n hôtes : $(echo $hosts | tr ' ' ',')" "$( [[ "$n" -ge 2 ]] && echo '✅ OK' || echo '❌ KO')"

# 6. Panne d'une instance
victim="$(echo "$hosts" | head -1)"
aws ec2 terminate-instances --instance-ids "$victim" >/dev/null
fail=0
for _ in $(seq 1 30); do
  c="$(curl -s -o /dev/null -w '%{http_code}' --max-time 5 "$URL")"; [[ "$c" == "200" ]] || fail=$((fail+1)); sleep 2
done
row "Panne" "terminate-instances $victim + 30 requêtes / 60 s" "Service toujours disponible" "$fail échec(s) sur 30" "$( [[ "$fail" -le 2 ]] && echo '✅ OK' || echo '❌ KO')"

# 7. Auto Scaling : capacité 2 -> 3 puis retour à 2
aws autoscaling set-desired-capacity --auto-scaling-group-name "$ASG" --desired-capacity 3
for _ in $(seq 1 30); do
  inservice="$(aws autoscaling describe-auto-scaling-groups --auto-scaling-group-names "$ASG" \
    --query 'length(AutoScalingGroups[0].Instances[?LifecycleState==`InService`])' --output text)"
  [[ "$inservice" -ge 3 ]] && break; sleep 10
done
row "Auto Scaling" "set-desired-capacity 3" "3 instances InService" "$inservice InService" "$( [[ "$inservice" -ge 3 ]] && echo '✅ OK' || echo '❌ KO')"
aws autoscaling set-desired-capacity --auto-scaling-group-name "$ASG" --desired-capacity 2

# 8. Sécurité DB : pas d'IP publique, connexion depuis Internet impossible
public="$(aws rds describe-db-instances --db-instance-identifier "cloud5-$ENV-db" \
  --query 'DBInstances[0].PubliclyAccessible' --output text)"
if timeout 8 bash -c "</dev/tcp/$DB_HOST/5432" 2>/dev/null; then reach="connexion ouverte"; else reach="connexion refusée/expirée"; fi
row "Sécurité DB" "PubliclyAccessible + TCP 5432 depuis l'extérieur" "Accès refusé" "PubliclyAccessible=$public, $reach" \
  "$( [[ "$public" == "False" && "$reach" != "connexion ouverte" ]] && echo '✅ OK' || echo '❌ KO')"

echo
echo "Test « Destruction » : lancer ./scripts/deploy.sh $ENV destroy puis vérifier l'absence de ressources :"
echo "  aws resourcegroupstaggingapi get-resources --tag-filters Key=Environment,Values=$ENV"
echo
echo "Résultats écrits dans $OUT"
