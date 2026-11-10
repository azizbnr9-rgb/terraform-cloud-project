# Module `compute`

Launch Template + Auto Scaling Group réparti sur les sous-réseaux privés, enregistré dans le Target Group de l'ALB.

- AMI **Amazon Linux 2023** récupérée dynamiquement via SSM Parameter Store.
- **IMDSv2 obligatoire**, volume racine **gp3 chiffré**.
- `user_data` : installe nginx, publie une page avec hostname / instance-id / AZ et un endpoint `/health`.
- Health check de type **ELB** : une instance jugée *Unhealthy* par l'ALB est remplacée automatiquement.
- Politique **Target Tracking** sur la CPU moyenne (`cpu_target_value`).
- `instance_refresh` *Rolling* (50 % minimum sain) lors d'un changement de Launch Template.
- `desired_capacity` ignoré après création pour permettre le test d'Auto Scaling manuel.

## Entrées

| Nom | Type | Défaut | Description |
|-----|------|--------|-------------|
| `name_prefix` | string | — | Préfixe |
| `environment` | string | — | Environnement affiché |
| `instance_type` | string | `t3.micro` | Type EC2 (validé) |
| `ami_ssm_parameter` | string | AL2023 x86_64 | Source de l'AMI |
| `app_subnet_ids` | list(string) | — | ≥ 2 sous-réseaux (validé) |
| `app_sg_id` | string | — | SG applicatif |
| `instance_profile_name` | string | — | Profil IAM |
| `target_group_arn` | string | — | Target Group |
| `app_port` | number | `80` | Port nginx |
| `min_size` / `max_size` / `desired_capacity` | number | `2` / `4` / `2` | Capacité |
| `cpu_target_value` | number | `50` | Cible CPU (%) |
| `root_volume_size` | number | `8` | Gio |
| `detailed_monitoring` | bool | `false` | Monitoring 1 min |
| `tags` | map(string) | `{}` | Tags |

## Sorties

`asg_name`, `asg_arn`, `launch_template_id`, `ami_id` (sensible).

## Exemple

```hcl
module "compute" {
  source                = "../../modules/compute"
  name_prefix           = "cloud5-dev"
  environment           = "dev"
  app_subnet_ids        = module.network.app_subnet_ids
  app_sg_id             = module.security.app_sg_id
  instance_profile_name = module.security.instance_profile_name
  target_group_arn      = module.load_balancer.target_group_arn
}
```
