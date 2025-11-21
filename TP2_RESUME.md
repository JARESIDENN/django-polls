# TP2 : Déploiement de l'image Django Polls sur Amazon ECR avec Terraform

## 📋 Résumé du TP

Ce TP configure le déploiement automatisé d'une application Django vers Amazon ECR (Elastic Container Registry) en utilisant Terraform.

## ✅ Tâches accomplies

### 1. ✅ Ajout du provider AWS dans la stack Terraform

Le fichier `main.tf` a été mis à jour avec :
- Provider AWS (hashicorp/aws ~> 5.0)
- Configuration de la région AWS (paramétrable via variables)
- Provider Docker existant maintenu pour la gestion des images

### 2. ✅ Création du repository ECR

Ressources Terraform créées :
- **aws_ecr_repository** : Repository pour stocker les images Django
  - Nom configurable (défaut: `django-polls`)
  - Scan de sécurité automatique activé (`scan_on_push = true`)
  - Tags pour l'organisation et le suivi

- **aws_ecr_lifecycle_policy** : Politique de nettoyage automatique
  - Conservation des 5 dernières images
  - Suppression automatique des anciennes images

### 3. ✅ Orchestration du push Docker vers ECR

Workflow Terraform complet :
1. **docker_image** : Build de l'image localement depuis le Dockerfile
2. **docker_tag** : Tag de l'image pour le repository ECR
3. **docker_registry_image** : Push automatique vers ECR
4. **data.aws_ecr_authorization_token** : Authentification automatique

## 📁 Fichiers créés/modifiés

### Fichiers Terraform principaux
- ✅ `main.tf` - Configuration principale (providers + ressources AWS ECR)
- ✅ `variables.tf` - Variables paramétrables (région, nom repository, environment, tag)
- ✅ `outputs.tf` - Outputs enrichis (URLs ECR, ARN, registry ID)
- ✅ `terraform.tfvars.example` - Exemple de configuration personnalisée

### Documentation
- ✅ `TERRAFORM_ECR.md` - Guide complet de déploiement sur ECR
- ✅ `COMMANDS.md` - Référence des commandes Terraform, AWS CLI et Docker
- ✅ `README.md` - Mise à jour avec instructions ECR

### Scripts d'automatisation
- ✅ `deploy-to-ecr.ps1` - Script PowerShell de déploiement automatisé
- ✅ `cleanup.ps1` - Script de nettoyage des ressources

### Autres fichiers
- ✅ `.gitignore` - Ignore les fichiers Terraform sensibles et temporaires

## 🚀 Architecture de déploiement

```
┌─────────────────┐
│  Dockerfile     │
└────────┬────────┘
         │
         ▼
┌─────────────────┐     Terraform      ┌──────────────────┐
│ docker_image    │─────orchestrates───▶│ AWS ECR          │
│ (Build local)   │                     │ Repository       │
└────────┬────────┘                     └──────────────────┘
         │                                       ▲
         ▼                                       │
┌─────────────────┐                             │
│ docker_tag      │                             │
│ (Tag pour ECR)  │                             │
└────────┬────────┘                             │
         │                                       │
         ▼                                       │
┌─────────────────┐                             │
│ docker_registry │─────────push────────────────┘
│ _image          │
└─────────────────┘
```

## 🔧 Configuration

### Variables disponibles

| Variable | Description | Valeur par défaut |
|----------|-------------|-------------------|
| `aws_region` | Région AWS | `us-east-1` |
| `ecr_repository_name` | Nom du repository ECR | `django-polls` |
| `environment` | Environnement de déploiement | `development` |
| `image_tag` | Tag de l'image Docker | `latest` |

### Ressources AWS créées

1. **ECR Repository** (`aws_ecr_repository.django_polls`)
   - Stockage des images Docker
   - Scan de sécurité automatique
   - Tags pour organisation

2. **ECR Lifecycle Policy** (`aws_ecr_lifecycle_policy.django_polls`)
   - Limite à 5 images conservées
   - Nettoyage automatique

3. **ECR Authorization Token** (`data.aws_ecr_authorization_token.token`)
   - Authentification automatique pour Docker

## 📊 Outputs Terraform

Après déploiement, Terraform expose :

- `ecr_repository_url` : URL complète du repository ECR
- `ecr_repository_arn` : ARN du repository
- `ecr_image_uri` : URI complète de l'image (pour ECS/EKS/Fargate)
- `ecr_registry_id` : ID du registry AWS

## 🎯 Utilisation

### Déploiement rapide (recommandé)
```powershell
.\deploy-to-ecr.ps1
```

### Déploiement manuel
```powershell
# 1. Initialiser Terraform
terraform init

# 2. Voir le plan
terraform plan

# 3. Appliquer
terraform apply
```

### Personnalisation
```powershell
# Utiliser une région différente
terraform apply -var="aws_region=eu-west-1"

# Utiliser un fichier de variables personnalisé
cp terraform.tfvars.example terraform.tfvars
# Éditer terraform.tfvars
terraform apply
```

## 🔐 Prérequis

1. **AWS CLI** configuré avec credentials valides
   ```powershell
   aws configure
   ```

2. **Docker** en cours d'exécution (Docker Desktop sur Windows)

3. **Terraform** installé (>= 1.0)

4. **Permissions AWS IAM** nécessaires :
   - `ecr:CreateRepository`
   - `ecr:PutImage`
   - `ecr:InitiateLayerUpload`
   - `ecr:UploadLayerPart`
   - `ecr:CompleteLayerUpload`
   - `ecr:PutLifecyclePolicy`

## 📝 Points techniques importants

### 1. Authentification automatique
Le provider Docker utilise automatiquement le token ECR via `data.aws_ecr_authorization_token`.

### 2. Build et Push orchestrés
Terraform gère le cycle complet :
- Build de l'image depuis le Dockerfile
- Tag pour le repository ECR
- Authentification AWS
- Push vers ECR

### 3. Gestion du cycle de vie
La politique ECR limite automatiquement le nombre d'images pour éviter les coûts de stockage.

### 4. Scan de sécurité
Chaque image poussée est automatiquement scannée pour détecter les vulnérabilités.

## 🧪 Vérification du déploiement

```powershell
# Voir les outputs Terraform
terraform output

# Vérifier le repository ECR
aws ecr describe-repositories --repository-names django-polls

# Lister les images
aws ecr list-images --repository-name django-polls

# Voir les détails d'une image
aws ecr describe-images --repository-name django-polls
```

## 🧹 Nettoyage

```powershell
# Script automatisé
.\cleanup.ps1

# Ou manuellement
terraform destroy
```

## 📚 Documentation complète

- **Guide de déploiement** : [TERRAFORM_ECR.md](TERRAFORM_ECR.md)
- **Référence des commandes** : [COMMANDS.md](COMMANDS.md)
- **Documentation Terraform** : Voir les commentaires dans `main.tf`

## 💰 Considérations de coût

- **Repository ECR** : Gratuit
- **Stockage** : ~$0.10/GB/mois (500 MB gratuits)
- **Transfert de données** : Variable selon l'utilisation
- **Limite à 5 images** via lifecycle policy pour contrôler les coûts

## 🎓 Concepts Terraform utilisés

1. **Multiple Providers** : AWS + Docker
2. **Data Sources** : `aws_ecr_authorization_token`
3. **Resource Dependencies** : `depends_on`
4. **Variables** : Configuration paramétrable
5. **Outputs** : Exposition des informations de déploiement
6. **Lifecycle Policies** : Gestion automatisée des ressources

## ✨ Fonctionnalités avancées

- ✅ Build automatique de l'image Docker
- ✅ Authentification ECR automatique
- ✅ Push orchestré vers ECR
- ✅ Scan de sécurité automatique
- ✅ Nettoyage automatique des anciennes images
- ✅ Tags pour organisation
- ✅ Outputs complets pour intégration ECS/EKS
- ✅ Scripts PowerShell d'automatisation
- ✅ Documentation exhaustive

## 🔄 Workflow CI/CD possible

Ce setup peut être intégré dans un pipeline CI/CD :

1. **GitHub Actions** ou **GitLab CI** exécute `terraform apply`
2. L'image est automatiquement construite et poussée vers ECR
3. Les outputs Terraform sont utilisés pour déployer sur ECS/EKS/Fargate

Exemple d'output pour ECS :
```powershell
$imageUri = terraform output -raw ecr_image_uri
# Utiliser $imageUri dans la task definition ECS
```

## 🎯 Objectifs du TP atteints

- ✅ Provider AWS ajouté et configuré
- ✅ Repository ECR créé avec Terraform
- ✅ Image Docker découverte et construite automatiquement
- ✅ Push orchestré vers ECR via Terraform
- ✅ Documentation complète fournie
- ✅ Scripts d'automatisation créés
- ✅ Bonnes pratiques appliquées (lifecycle, scanning, tags)

---

**Auteur** : Configuration Terraform automatisée  
**Date** : 21 novembre 2025  
**Technologies** : Terraform, AWS ECR, Docker, Django, PowerShell
