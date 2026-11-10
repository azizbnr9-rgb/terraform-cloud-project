# Module `security`

Security Groups chaînés et rôle IAM des instances.

```
Internet ──80/443──▶ sg-alb ──app_port──▶ sg-app ──5432──▶ sg-db
```

- **sg-alb** : HTTP (et HTTPS si `enable_https`) depuis `allowed_web_cidrs` ; sortie uniquement vers `sg-app`.
- **sg-app** : entrée `app_port` **uniquement** depuis `sg-alb` ; sortie 80/443 (paquets, SSM via NAT) et `db_port` vers `sg-db`. **Aucun port 22.**
- **sg-db** : entrée `db_port` **uniquement** depuis `sg-app` ; aucune sortie.
- **Rôle EC2** : `AmazonSSMManagedInstanceCore` (administration par Session Manager, tracée dans CloudTrail) + lecture seule de `s3://<bucket>/assets/*`.

## Entrées

| Nom | Type | Défaut | Description |
|-----|------|--------|-------------|
| `name_prefix` | string | — | Préfixe |
| `vpc_id` | string | — | VPC cible |
| `app_port` | number | `80` | Port applicatif (validé) |
| `db_port` | number | `5432` | Port base de données (validé) |
| `allowed_web_cidrs` | list(string) | `["0.0.0.0/0"]` | Origines autorisées vers l'ALB |
| `enable_https` | bool | `false` | Ouvre 443 |
| `assets_bucket_arn` | string | — | Bucket applicatif |
| `tags` | map(string) | `{}` | Tags |

## Sorties

`alb_sg_id`, `app_sg_id`, `db_sg_id`, `instance_profile_name`, `ec2_role_arn`.

## Exemple

```hcl
module "security" {
  source            = "../../modules/security"
  name_prefix       = "cloud5-dev"
  vpc_id            = module.network.vpc_id
  assets_bucket_arn = module.storage.bucket_arn
}
```
