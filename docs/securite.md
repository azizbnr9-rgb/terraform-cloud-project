# Choix de sécurité

## 1. Segmentation réseau

| Mesure | Implémentation | Justification |
|--------|----------------|---------------|
| 3 niveaux de sous-réseaux | public / app / db | Seul l'ALB est exposé |
| DB isolée | table de routage `rt-db` sans route par défaut | Même compromis, RDS ne peut ni être joint ni exfiltrer vers Internet |
| Sortie contrôlée | NAT Gateway ; SG app limité à 80/443 sortant | Mises à jour et SSM uniquement |
| IP publiques | `map_public_ip_on_launch = false` partout | Aucune instance adressable depuis Internet |

## 2. Security Groups (moindre ouverture)

| SG | Entrant | Sortant |
|----|---------|---------|
| `sg-alb` | 80 (443 si HTTPS) depuis `allowed_web_cidrs` | `app_port` → `sg-app` uniquement |
| `sg-app` | `app_port` **depuis `sg-alb` uniquement** | 80/443 → Internet (NAT), 5432 → `sg-db` |
| `sg-db` | 5432 **depuis `sg-app` uniquement** | aucun |

Les règles référencent des **Security Groups**, pas des CIDR : une nouvelle instance de l'ASG est autorisée automatiquement, une machine du VPC hors ASG ne l'est pas.

## 3. Accès administratif

- **Aucun port 22, aucune paire de clés SSH.**
- Administration par **AWS Systems Manager Session Manager** (politique `AmazonSSMManagedInstanceCore`) : authentification IAM, sessions journalisées dans CloudTrail, aucune ouverture réseau entrante.
- Justification : l'accès est nominatif, révocable instantanément et traçable.

## 4. Secrets

| Secret | Traitement |
|--------|-----------|
| Mot de passe RDS | `manage_master_user_password = true` : généré et stocké par RDS dans **Secrets Manager** (rotation possible) ; absent de Git, des tfvars **et de l'état** |
| Identifiants AWS (poste) | CloudShell / SSO / variables de session ; jamais dans un fichier du dépôt |
| Identifiants AWS (CI) | OIDC (jetons de 1 h, aucun secret stocké) ; sinon secrets chiffrés GitHub, masqués dans les journaux |
| Fichiers sensibles | `.gitignore` : `*.tfstate*`, `.terraform/`, `*.secret.tfvars`, `.env`, `*.pem`, `credentials` |

## 5. Chiffrement

| Donnée | Au repos | En transit |
|--------|----------|-----------|
| État Terraform | SSE-KMS + bucket key | TLS imposé (politique `DenyInsecureTransport`) |
| Bucket applicatif | SSE-S3 AES-256 (requis par les journaux ALB) | TLS imposé |
| RDS | stockage chiffré KMS, sauvegardes et snapshots chiffrés | `rds.force_ssl = 1` |
| EBS des instances | gp3 chiffré | — |
| Trafic client | — | HTTPS TLS 1.2/1.3 dès qu'un certificat ACM est fourni |

## 6. IAM — moindre privilège

| Identité | Droits |
|----------|--------|
| Profil EC2 | SSM Session Manager + `s3:GetObject` sur `assets/*` et `ListBucket` limité au préfixe |
| Rôle CI *plan* | `ReadOnlyAccess` + lecture/écriture de l'état ; assumable par les PR et `main` uniquement |
| Rôle CI *apply* | services du projet + IAM limité aux ressources `cloud5-*` ; assumable **uniquement** depuis les GitHub Environments `dev`/`test`/`prod` |
| Learner Lab | création IAM impossible → `LabInstanceProfile` (écart documenté, imposé par la plateforme) |

## 7. Durcissement complémentaire

- **IMDSv2 obligatoire** (`http_tokens = required`, hop limit 1) : bloque le vol d'identifiants par SSRF.
- ALB : `drop_invalid_header_fields = true` (anti request smuggling), journaux d'accès dans S3.
- S3 : Public Access Block (4 options), ACL désactivées (`BucketOwnerEnforced`), versioning.
- Protection contre la suppression de l'ALB et de RDS + snapshot final en **prod**.
- Analyse statique **Checkov** dans le pipeline.
- `prod` : déploiement impossible depuis une branche non protégée (règle de branche de l'environnement GitHub + condition `sub` du rôle OIDC).

## 8. Exceptions documentées

| Exception | Raison | Atténuation |
|-----------|--------|-------------|
| ALB ouvert à `0.0.0.0/0` | application publique | restreignable via `allowed_web_cidrs` ; WAF envisageable |
| HTTP sans TLS en dev/test | pas de domaine/certificat dans le lab | redirection HTTPS automatique dès qu'un `certificate_arn` est fourni |
| Rôle EC2 du Learner Lab | IAM verrouillé | profil fourni par AWS Academy, compte éphémère |
