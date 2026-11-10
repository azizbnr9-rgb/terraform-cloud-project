# Module `load-balancer`

Application Load Balancer public, Target Group avec health check et listeners.

- Listener **HTTP:80** : `forward` vers le Target Group, ou redirection 301 vers HTTPS si `certificate_arn` est fourni.
- Listener **HTTPS:443** (optionnel) : politique TLS 1.2/1.3.
- Health check `GET /health` → `200`, toutes les 5 s, 2 succès/échecs.
- `drop_invalid_header_fields` activé ; journaux d'accès vers S3 si `access_logs_bucket` est fourni.

## Entrées

| Nom | Type | Défaut | Description |
|-----|------|--------|-------------|
| `name_prefix` | string | — | Préfixe (≤ 26 car., validé) |
| `vpc_id` | string | — | VPC |
| `public_subnet_ids` | list(string) | — | ≥ 2 sous-réseaux publics (validé) |
| `alb_sg_id` | string | — | SG de l'ALB |
| `app_port` | number | `80` | Port cible |
| `health_check_path` | string | `/health` | Chemin du health check |
| `certificate_arn` | string | `null` | Certificat ACM (active HTTPS) |
| `access_logs_bucket` | string | `null` | Bucket des journaux |
| `deletion_protection` | bool | `false` | Protection suppression |
| `tags` | map(string) | `{}` | Tags |

## Sorties

`alb_arn`, `alb_dns_name`, `alb_url`, `target_group_arn`, `alb_arn_suffix`, `target_group_arn_suffix`.

## Exemple

```hcl
module "load_balancer" {
  source             = "../../modules/load-balancer"
  name_prefix        = "cloud5-dev"
  vpc_id             = module.network.vpc_id
  public_subnet_ids  = module.network.public_subnet_ids
  alb_sg_id          = module.security.alb_sg_id
  access_logs_bucket = module.storage.bucket_name
}
```
