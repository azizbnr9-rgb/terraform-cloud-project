# Résultats des tests — dev

Exécution réelle le 2026-11-10 sur AWS Academy Learner Lab (us-east-1), 46 ressources déployées.
URL testée : http://cloud5-dev-alb-1442745685.us-east-1.elb.amazonaws.com

| Test | Procédure | Résultat attendu | Résultat obtenu | Statut |
|------|-----------|------------------|-----------------|--------|
| Format | `terraform fmt -check -recursive` | Aucune différence | code retour 0 | ✅ OK |
| Validation | `terraform validate` | Success | Success! The configuration is valid. | ✅ OK |
| Plan | `terraform plan` | Plan sans erreur | Plan sans erreur ; après correctif `No changes` | ✅ OK |
| Accès Web | `curl <alb_url>` | HTTP 200 | HTTP 200 | ✅ OK |
| Répartition | 20 requêtes sur l'ALB | ≥ 2 hôtes | 2 hôtes : us-east-1a et us-east-1b | ✅ OK |
| Panne (arrêt piloté) | `terminate-instance-in-auto-scaling-group` + 30 requêtes / 60 s | Service toujours disponible | 0 échec sur 30, instance remplacée | ✅ OK |
| Panne (arrêt brutal) | `ec2 terminate-instances` + 30 requêtes / 60 s | Service toujours disponible | service maintenu, 4 échecs sur 30 pendant ~8 s (détection health check) | ⚠️ OK avec réserve |
| Auto Scaling | `set-desired-capacity 3` | 3 instances InService | 3 InService, puis retour à 2 | ✅ OK |
| Sécurité DB | `PubliclyAccessible` + TCP 5432 depuis CloudShell | Accès refusé | PubliclyAccessible=False, connexion expirée | ✅ OK |
| Destruction | `terraform destroy` | Ressources supprimées | Destroy complete, aucune ressource `Environment=dev` restante | ✅ OK |

## Correctifs issus des tests réels

1. Descriptions de Security Groups : l'API EC2 refuse apostrophes et accents → texte ASCII.
2. `rds.force_ssl` (paramètre statique) : `apply_method = "pending-reboot"` → plus de dérive du plan.
3. Health check : intervalle 15 s → 5 s, timeout 3 s → détection d'une instance morte en ~10 s.

Preuves : `docs/preuves-dev.txt`, `docs/capture-page-web.jpg`, `docs/capture-target-group.jpg`.
