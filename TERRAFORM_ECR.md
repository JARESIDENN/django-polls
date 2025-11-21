# Déploiement Django Polls sur Amazon ECR avec Terraform

## Prérequis

1. **Terraform** installé (version >= 1.0)
2. **Docker** installé et en cours d'exécution
3. **AWS CLI** configuré avec vos credentials
   ```powershell
   aws configure
   ```
4. Permissions AWS nécessaires :
   - ECR (création de repository, push d'images)
   - IAM (pour les authentifications)

## Configuration AWS

Assurez-vous que vos credentials AWS sont configurés :

```powershell
# Vérifier la configuration
aws sts get-caller-identity

# Si nécessaire, configurer AWS CLI
aws configure
# Entrez : AWS Access Key ID, Secret Access Key, Region (ex: us-east-1)
```

## Structure du projet

```
.
├── main.tf              # Configuration principale Terraform
├── variables.tf         # Variables de configuration
├── outputs.tf           # Outputs après déploiement
├── Dockerfile           # Image Docker de l'application
├── requirements.txt     # Dépendances Python
└── TERRAFORM_ECR.md     # Ce fichier
```

## Étapes de déploiement

### 1. Initialiser Terraform

```powershell
terraform init
```

Cette commande télécharge les providers nécessaires (AWS et Docker).

### 2. Vérifier le plan d'exécution

```powershell
terraform plan
```

Cela vous montrera :
- Le repository ECR qui sera créé
- L'image Docker qui sera construite
- L'image qui sera poussée vers ECR
- Le conteneur local (optionnel)

### 3. Appliquer la configuration

```powershell
terraform apply
```

Tapez `yes` pour confirmer. Terraform va :
1. Créer le repository ECR sur AWS
2. Construire l'image Docker localement
3. S'authentifier auprès d'ECR
4. Tagger l'image pour ECR
5. Pousser l'image vers ECR
6. Démarrer le conteneur local (optionnel)

### 4. Vérifier le déploiement

```powershell
# Voir les outputs
terraform output

# Vérifier le repository ECR
aws ecr describe-repositories --repository-names django-polls

# Lister les images dans ECR
aws ecr list-images --repository-name django-polls
```

## Personnalisation

### Changer la région AWS

Modifiez dans `main.tf` ou utilisez une variable :

```powershell
terraform apply -var="aws_region=eu-west-1"
```

### Changer le nom du repository

```powershell
terraform apply -var="ecr_repository_name=mon-app"
```

## Outputs disponibles

Après le déploiement, Terraform affiche :

- `ecr_repository_url` : URL du repository ECR
- `ecr_image_uri` : URI complète de l'image (pour déploiement ECS/EKS)
- `ecr_repository_arn` : ARN du repository
- `container_id` : ID du conteneur local
- `application_url` : URL de l'app locale (http://localhost:8000)

## Utiliser l'image depuis ECR

### Pull l'image depuis ECR

```powershell
# S'authentifier
aws ecr get-login-password --region us-east-1 | docker login --username AWS --password-stdin <account-id>.dkr.ecr.us-east-1.amazonaws.com

# Pull l'image
docker pull <ecr_repository_url>:latest
```

### Utiliser avec ECS/EKS

L'URI de l'image (`ecr_image_uri` output) peut être utilisée directement dans :
- Amazon ECS Task Definitions
- Kubernetes Deployments
- AWS Fargate

## Nettoyage

Pour supprimer toutes les ressources créées :

```powershell
# Supprimer le conteneur local
terraform destroy -target=docker_container.django_polls_app

# Supprimer toutes les ressources
terraform destroy
```

⚠️ **Attention** : Les images dans ECR ne sont pas supprimées automatiquement. Pour les supprimer :

```powershell
aws ecr batch-delete-image --repository-name django-polls --image-ids imageTag=latest
```

## Résolution de problèmes

### Erreur d'authentification Docker avec ECR

```powershell
aws ecr get-login-password --region us-east-1 | docker login --username AWS --password-stdin <account-id>.dkr.ecr.us-east-1.amazonaws.com
```

### Erreur "Docker daemon not running"

Vérifiez que Docker Desktop est démarré sur Windows.

### Erreur de permissions AWS

Vérifiez que votre utilisateur IAM a les permissions ECR nécessaires :
- `ecr:CreateRepository`
- `ecr:PutImage`
- `ecr:InitiateLayerUpload`
- `ecr:UploadLayerPart`
- `ecr:CompleteLayerUpload`

## Coûts AWS

- Repository ECR : Gratuit (jusqu'à 500 MB)
- Stockage : ~$0.10/GB/mois
- Transfert de données : Variable selon l'utilisation

## Ressources

- [Documentation Terraform AWS Provider](https://registry.terraform.io/providers/hashicorp/aws/latest/docs)
- [Documentation Amazon ECR](https://docs.aws.amazon.com/ecr/)
- [Docker Provider Terraform](https://registry.terraform.io/providers/kreuzwerker/docker/latest/docs)
