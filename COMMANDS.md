# Commandes Utiles - Terraform & AWS ECR

## Commandes Terraform

### Initialisation et déploiement
```powershell
# Initialiser Terraform (première fois)
terraform init

# Voir le plan d'exécution
terraform plan

# Appliquer la configuration
terraform apply

# Appliquer sans confirmation
terraform apply -auto-approve

# Détruire les ressources
terraform destroy
```

### Variables
```powershell
# Utiliser une région spécifique
terraform apply -var="aws_region=eu-west-1"

# Utiliser un fichier de variables
terraform apply -var-file="production.tfvars"
```

### Outputs
```powershell
# Voir tous les outputs
terraform output

# Voir un output spécifique
terraform output ecr_repository_url

# Format JSON
terraform output -json
```

### Maintenance
```powershell
# Reformater les fichiers
terraform fmt

# Valider la configuration
terraform validate

# Voir l'état actuel
terraform show

# Lister les ressources
terraform state list
```

## Commandes AWS CLI pour ECR

### Authentification
```powershell
# Obtenir le token et s'authentifier
aws ecr get-login-password --region us-east-1 | docker login --username AWS --password-stdin <account-id>.dkr.ecr.us-east-1.amazonaws.com
```

### Gestion des repositories
```powershell
# Lister les repositories
aws ecr describe-repositories

# Voir un repository spécifique
aws ecr describe-repositories --repository-names django-polls

# Créer un repository manuellement
aws ecr create-repository --repository-name django-polls

# Supprimer un repository
aws ecr delete-repository --repository-name django-polls --force
```

### Gestion des images
```powershell
# Lister les images
aws ecr list-images --repository-name django-polls

# Voir les détails d'une image
aws ecr describe-images --repository-name django-polls

# Supprimer une image
aws ecr batch-delete-image --repository-name django-polls --image-ids imageTag=latest

# Supprimer toutes les images non taguées
aws ecr list-images --repository-name django-polls --filter "tagStatus=UNTAGGED" --query 'imageIds[*]' --output json | ConvertFrom-Json | ForEach-Object { aws ecr batch-delete-image --repository-name django-polls --image-ids imageDigest=$_.imageDigest }
```

### Informations
```powershell
# Obtenir l'URL du repository
aws ecr describe-repositories --repository-names django-polls --query 'repositories[0].repositoryUri' --output text

# Obtenir le Registry ID
aws ecr describe-repositories --repository-names django-polls --query 'repositories[0].registryId' --output text

# Obtenir l'identité du compte
aws sts get-caller-identity
```

## Commandes Docker

### Build et Tag
```powershell
# Construire l'image
docker build -t django-polls:latest .

# Tagger pour ECR (remplacez les valeurs)
docker tag django-polls:latest <account-id>.dkr.ecr.us-east-1.amazonaws.com/django-polls:latest
```

### Push vers ECR
```powershell
# Push vers ECR
docker push <account-id>.dkr.ecr.us-east-1.amazonaws.com/django-polls:latest
```

### Pull depuis ECR
```powershell
# Pull depuis ECR
docker pull <account-id>.dkr.ecr.us-east-1.amazonaws.com/django-polls:latest
```

### Gestion locale
```powershell
# Lister les images
docker images

# Supprimer une image
docker rmi django-polls:latest

# Lister les conteneurs
docker ps -a

# Arrêter un conteneur
docker stop django-polls-app

# Supprimer un conteneur
docker rm django-polls-app
```

## Scripts PowerShell

### Déploiement automatisé
```powershell
.\deploy-to-ecr.ps1
```

### Nettoyage
```powershell
.\cleanup.ps1
```

## Workflows complets

### Déploiement initial
```powershell
# 1. Configurer AWS
aws configure

# 2. Déployer avec Terraform
terraform init
terraform apply

# 3. Vérifier
aws ecr describe-repositories --repository-names django-polls
terraform output
```

### Mise à jour de l'image
```powershell
# 1. Modifier le code
# 2. Réappliquer Terraform (reconstruit et push automatiquement)
terraform apply

# Ou manuellement
docker build -t django-polls:latest .
aws ecr get-login-password --region us-east-1 | docker login --username AWS --password-stdin <account-id>.dkr.ecr.us-east-1.amazonaws.com
docker tag django-polls:latest <ecr-url>:latest
docker push <ecr-url>:latest
```

### Nettoyage complet
```powershell
# 1. Détruire les ressources Terraform
terraform destroy

# 2. Nettoyer les images locales
docker system prune -a
```

## Dépannage

### Vérifier Docker
```powershell
docker info
docker version
```

### Vérifier AWS
```powershell
aws --version
aws sts get-caller-identity
aws configure list
```

### Vérifier Terraform
```powershell
terraform version
terraform validate
```

### Logs et debug
```powershell
# Logs Terraform détaillés
$env:TF_LOG="DEBUG"
terraform apply

# Logs Docker
docker logs django-polls-app
```

## Variables d'environnement utiles

```powershell
# Région AWS par défaut
$env:AWS_DEFAULT_REGION="us-east-1"

# Profile AWS
$env:AWS_PROFILE="default"

# Debug Terraform
$env:TF_LOG="DEBUG"
$env:TF_LOG_PATH="terraform.log"
```
