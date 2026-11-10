# Module `network`

Crée le socle réseau : VPC sur au moins deux AZ, sous-réseaux publics / applicatifs / base de données, Internet Gateway, NAT Gateway(s) et tables de routage.

| Tier | Route par défaut | Usage |
|------|------------------|-------|
| public | Internet Gateway | ALB, NAT Gateway |
| app | NAT Gateway | Instances EC2 (sortie contrôlée pour les mises à jour et SSM) |
| db | aucune | RDS (aucun accès Internet, ni entrant ni sortant) |

## Entrées

| Nom | Type | Défaut | Description |
|-----|------|--------|-------------|
| `name_prefix` | string | — | Préfixe `<projet>-<env>` |
| `vpc_cidr` | string | — | CIDR du VPC (validé) |
| `azs` | list(string) | — | AZ utilisées (≥ 2, validé) |
| `public_subnet_cidrs` | list(string) | — | Un CIDR par AZ |
| `app_subnet_cidrs` | list(string) | — | Un CIDR par AZ |
| `db_subnet_cidrs` | list(string) | — | Un CIDR par AZ |
| `single_nat_gateway` | bool | `true` | Une NAT unique (économique) ou une par AZ (HA) |
| `tags` | map(string) | `{}` | Tags additionnels |

## Sorties

`vpc_id`, `vpc_cidr`, `public_subnet_ids`, `app_subnet_ids`, `db_subnet_ids`, `nat_public_ips`.

## Exemple

```hcl
module "network" {
  source              = "../../modules/network"
  name_prefix         = "cloud5-dev"
  vpc_cidr            = "10.20.0.0/16"
  azs                 = ["eu-west-3a", "eu-west-3b"]
  public_subnet_cidrs = ["10.20.1.0/24", "10.20.2.0/24"]
  app_subnet_cidrs    = ["10.20.11.0/24", "10.20.12.0/24"]
  db_subnet_cidrs     = ["10.20.21.0/24", "10.20.22.0/24"]
  single_nat_gateway  = true
}
```
