# Tests obligatoires

Automatisés par `./scripts/run-tests.sh <env>` (résultats écrits dans `docs/test-results-<env>.md`).

| Test | Procédure | Résultat attendu | Vérification automatique |
|------|-----------|------------------|--------------------------|
| Format | `terraform fmt -check -recursive` | Aucune différence | code retour 0 |
| Validation | `terraform validate` | Success | code retour 0 |
| Plan | `terraform plan` | Plan sans erreur | ligne `Plan:` ou `No changes` |
| Accès Web | ouvrir `terraform output -raw alb_url` | Page disponible | HTTP 200 |
| Répartition | 20 requêtes successives | Plusieurs hôtes observés | ≥ 2 `instance-id` distincts |
| Panne | `aws ec2 terminate-instances` sur une instance, puis 30 requêtes en 60 s | Service toujours disponible | ≤ 2 échecs ; l'ASG relance une instance |
| Auto Scaling | `aws autoscaling set-desired-capacity … 3` | Nombre d'instances adapté | 3 instances `InService`, puis retour à 2 |
| Sécurité DB | `PubliclyAccessible` + connexion TCP 5432 depuis l'extérieur du VPC | Accès refusé | `False` + connexion expirée |
| Destruction | `terraform destroy` | Ressources supprimées | `aws resourcegroupstaggingapi get-resources --tag-filters Key=Environment,Values=<env>` vide |

## Tests manuels complémentaires (captures)

```bash
URL=$(terraform -chdir=environments/dev output -raw alb_url)
for i in $(seq 10); do curl -s $URL | grep -o 'i-[0-9a-f]*' | head -1; done | sort | uniq -c

ASG=$(terraform -chdir=environments/dev output -raw asg_name)
aws autoscaling describe-auto-scaling-groups --auto-scaling-group-names $ASG \
  --query 'AutoScalingGroups[0].Instances[].[InstanceId,AvailabilityZone,LifecycleState,HealthStatus]' --output table

aws elbv2 describe-target-health --target-group-arn $(aws elbv2 describe-target-groups \
  --names cloud5-dev-tg --query 'TargetGroups[0].TargetGroupArn' --output text) --output table
```

## Captures demandées (checklist)

- [ ] Pipeline : jobs *fmt & validate* et *plan* verts
- [ ] VPC et 6 sous-réseaux (console VPC, filtre `cloud5-dev`)
- [ ] Load Balancer + Target Group **healthy**
- [ ] Auto Scaling Group et instances dans 2 AZ
- [ ] RDS : *Publicly accessible = No*, subnet group DB
- [ ] Bucket d'état (objets `dev/terraform.tfstate`, versions)
- [ ] Page Web avec deux hôtes différents
- [ ] Résultat du test de panne (`docs/test-results-dev.md`)
