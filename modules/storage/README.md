# Module `storage`

Bucket S3 applicatif pour les ressources (`assets/`), les journaux ALB (`alb-logs/`) et les sauvegardes (`backups/`).

- **Accès public bloqué** (4 options du Public Access Block) et ACL désactivées (`BucketOwnerEnforced`).
- **Versioning** activé, **chiffrement SSE-S3** (AES-256, compatible avec les journaux ALB).
- Politique de bucket : refus de tout accès non-TLS ; écriture des journaux autorisée au seul service ELB de la région.
- Cycle de vie : journaux → STANDARD_IA à 30 j puis expiration ; sauvegardes → Glacier IR à 30 j ; purge des versions non courantes et des uploads incomplets.
- Nom unique : `<prefixe>-assets-<compte>-<region>`.

## Entrées

| Nom | Type | Défaut | Description |
|-----|------|--------|-------------|
| `name_prefix` | string | — | Préfixe |
| `force_destroy` | bool | `false` | Vider le bucket au destroy (dev/test) |
| `log_retention_days` | number | `90` | > 30 (validé) |
| `noncurrent_version_days` | number | `30` | ≥ 1 (validé) |
| `tags` | map(string) | `{}` | Tags |

## Sorties

`bucket_name`, `bucket_arn`.

## Exemple

```hcl
module "storage" {
  source        = "../../modules/storage"
  name_prefix   = "cloud5-dev"
  force_destroy = true
}
```
