# Estimation des coûts

Prix publics **à la demande, région us-east-1** (USD, hors taxes, base 730 h/mois). Ordres de grandeur à confirmer avec [AWS Pricing Calculator](https://calculator.aws/) avant engagement ; le trafic est supposé faible (démonstration).

## Ressources payantes identifiées

| Ressource | Tarif unitaire | dev / test | prod |
|-----------|----------------|-----------:|-----:|
| EC2 t3.micro (×2) | 0,0104 $/h | 15,18 | — |
| EC2 t3.small (×2) | 0,0208 $/h | — | 30,37 |
| EBS gp3 8 Gio (×2) | 0,08 $/Gio-mois | 1,28 | 1,28 |
| Application Load Balancer | 0,0225 $/h + LCU 0,008 $/h (≈1 LCU) | 22,27 | 22,27 |
| NAT Gateway | 0,045 $/h (+0,045 $/Go traité) | 32,85 (×1) | 65,70 (×2) |
| IPv4 publiques (ALB ×2, EIP NAT) | 0,005 $/h chacune | 10,95 (×3) | 14,60 (×4) |
| RDS db.t3.micro PostgreSQL Single-AZ | 0,018 $/h | 13,14 | — |
| RDS db.t3.small PostgreSQL Multi-AZ | 0,072 $/h | — | 52,56 |
| Stockage RDS gp3 20 Gio | 0,115 $/Gio-mois (×2 Multi-AZ) | 2,30 | 4,60 |
| Secrets Manager (1 secret) | 0,40 $/mois | 0,40 | 0,40 |
| S3 (Go + requêtes, journaux) | 0,023 $/Go | ≈ 0,50 | ≈ 1,00 |
| Données sortantes, CloudWatch de base | — | ≈ 1,00 | ≈ 2,00 |
| **Total mensuel estimé** | | **≈ 100 $** | **≈ 195 $** |
| **Coût horaire** | | **≈ 0,14 $** | **≈ 0,27 $** |

Gratuits : VPC, sous-réseaux, tables de routage, Security Groups, IAM, Launch Template, Auto Scaling, sauvegardes RDS jusqu'à la taille de la base, bucket d'état (quelques Ko).

## Coût d'une démonstration

| Scénario | Durée | Coût estimé |
|----------|-------|-------------|
| dev : apply + tests + destroy | 2 h | ≈ 0,30 $ |
| test : démonstration de soutenance | 4 h | ≈ 0,60 $ |
| dev oublié allumé une semaine | 168 h | ≈ 23 $ |

> AWS Academy Learner Lab : le budget du lab (souvent 50 ou 100 $) est décompté de ces montants ; les ressources sont arrêtées à la fin de chaque session de 4 h, mais **NAT Gateway, ALB, IPv4 et RDS continuent de coûter** tant qu'ils existent. D'où l'obligation de `terraform destroy`.

## Principaux postes et leviers

1. **NAT Gateway (≈ 33 %)** : une seule NAT en dev/test ; en alternative, points de terminaison VPC (S3 gateway gratuit, SSM interface) ou NAT instance.
2. **ALB (≈ 22 %)** : mutualiser un ALB entre environnements via des règles d'hôte si besoin.
3. **RDS** : Single-AZ hors prod ; arrêt manuel possible (7 jours max) ; Reserved Instances en prod (−30 à −40 %).
4. **EC2** : Savings Plans ou instances Spot pour une partie de l'ASG ; `t4g` (ARM) ≈ −20 %.
5. **Discipline** : `terraform destroy` systématique de `test`, alarme AWS Budgets, tags `Environment`/`Owner` pour l'imputation.
