# Module `database`

Instance **RDS PostgreSQL** dans un DB subnet group privé.

- `publicly_accessible = false`, aucun accès Internet (sous-réseaux DB sans route par défaut) ; seul `sg-app` peut se connecter.
- **Mot de passe géré par RDS dans Secrets Manager** (`manage_master_user_password`) : il n'apparaît ni dans Git, ni dans les tfvars, ni dans l'état.
- Stockage **gp3 chiffré** (KMS), auto-extension jusqu'à `max_allocated_storage`.
- Paramètre `rds.force_ssl = 1` : connexions TLS obligatoires.
- Multi-AZ, rétention des sauvegardes, protection contre la suppression et snapshot final paramétrables par environnement.

## Entrées

| Nom | Type | Défaut | Description |
|-----|------|--------|-------------|
| `name_prefix` | string | — | Préfixe |
| `db_subnet_ids` | list(string) | — | ≥ 2 sous-réseaux (validé) |
| `db_sg_id` | string | — | SG base de données |
| `engine_major_version` | string | `16` | 15/16/17 (validé) |
| `db_instance_class` | string | `db.t3.micro` | Classe (validée) |
| `db_name` | string | `appdb` | Base initiale (validée) |
| `db_username` | string | `dbadmin` | Utilisateur admin (noms réservés refusés) |
| `db_port` | number | `5432` | Port |
| `allocated_storage` / `max_allocated_storage` | number | `20` / `50` | Gio |
| `multi_az` | bool | `false` | Haute disponibilité |
| `backup_retention_days` | number | `1` | 0–35 (validé) |
| `deletion_protection` | bool | `false` | Protection |
| `skip_final_snapshot` | bool | `true` | Snapshot final |
| `tags` | map(string) | `{}` | Tags |

## Sorties

`db_endpoint`, `db_address`, `db_port`, `db_name`, `master_user_secret_arn`.

## Récupérer le mot de passe (opérateur autorisé)

```bash
aws secretsmanager get-secret-value --secret-id "$(terraform output -raw db_secret_arn)" \
  --query SecretString --output text
```
