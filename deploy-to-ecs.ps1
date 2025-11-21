# Script de déploiement complet sur ECS avec Terraform
# Usage: .\deploy-to-ecs.ps1

Write-Host "=== Déploiement Django Polls sur Amazon ECS ===" -ForegroundColor Cyan
Write-Host ""

# Vérifier les prérequis
Write-Host "Vérification des prérequis..." -ForegroundColor Yellow

# Docker
try {
    docker info > $null 2>&1
    if ($LASTEXITCODE -ne 0) {
        Write-Host "Erreur: Docker n'est pas en cours d'exécution." -ForegroundColor Red
        exit 1
    }
    Write-Host "✓ Docker actif" -ForegroundColor Green
} catch {
    Write-Host "Erreur: Docker n'est pas installé." -ForegroundColor Red
    exit 1
}

# AWS CLI
try {
    aws --version > $null 2>&1
    if ($LASTEXITCODE -ne 0) {
        Write-Host "Erreur: AWS CLI n'est pas installé." -ForegroundColor Red
        exit 1
    }
    Write-Host "✓ AWS CLI installé" -ForegroundColor Green
} catch {
    Write-Host "Erreur: AWS CLI n'est pas accessible." -ForegroundColor Red
    exit 1
}

# Terraform
try {
    terraform version > $null 2>&1
    if ($LASTEXITCODE -ne 0) {
        Write-Host "Erreur: Terraform n'est pas installé." -ForegroundColor Red
        exit 1
    }
    Write-Host "✓ Terraform installé" -ForegroundColor Green
} catch {
    Write-Host "Erreur: Terraform n'est pas accessible." -ForegroundColor Red
    exit 1
}

# AWS Credentials
try {
    $identity = aws sts get-caller-identity 2>&1
    if ($LASTEXITCODE -ne 0) {
        Write-Host "Erreur: Credentials AWS non configurés." -ForegroundColor Red
        exit 1
    }
    Write-Host "✓ Credentials AWS configurés" -ForegroundColor Green
} catch {
    Write-Host "Erreur lors de la vérification des credentials AWS." -ForegroundColor Red
    exit 1
}

Write-Host ""
Write-Host "=== Étape 1: Construction de l'image Docker ===" -ForegroundColor Cyan
$buildImage = Read-Host "Construire une nouvelle image Docker? (y/n)"
if ($buildImage -eq "y" -or $buildImage -eq "Y") {
    Write-Host "Construction de l'image..." -ForegroundColor Yellow
    docker build -t django-polls:latest .
    if ($LASTEXITCODE -ne 0) {
        Write-Host "Erreur lors de la construction de l'image." -ForegroundColor Red
        exit 1
    }
    Write-Host "✓ Image construite avec succès" -ForegroundColor Green
}

Write-Host ""
Write-Host "=== Étape 2: Initialisation Terraform ===" -ForegroundColor Cyan
terraform init
if ($LASTEXITCODE -ne 0) {
    Write-Host "Erreur lors de l'initialisation de Terraform." -ForegroundColor Red
    exit 1
}

Write-Host ""
Write-Host "=== Étape 3: Plan Terraform ===" -ForegroundColor Cyan
terraform plan
if ($LASTEXITCODE -ne 0) {
    Write-Host "Erreur lors de la génération du plan." -ForegroundColor Red
    exit 1
}

Write-Host ""
$confirm = Read-Host "Voulez-vous déployer l'infrastructure ECS? (yes/no)"
if ($confirm -ne "yes") {
    Write-Host "Déploiement annulé." -ForegroundColor Yellow
    exit 0
}

Write-Host ""
Write-Host "=== Étape 4: Déploiement de l'infrastructure ===" -ForegroundColor Cyan
terraform apply -auto-approve
if ($LASTEXITCODE -ne 0) {
    Write-Host "Erreur lors du déploiement." -ForegroundColor Red
    exit 1
}

Write-Host ""
Write-Host "=== Étape 5: Push de l'image vers ECR ===" -ForegroundColor Cyan
$region = terraform output -raw aws_region
$ecrUrl = terraform output -raw ecr_repository_url

Write-Host "Authentification avec ECR..." -ForegroundColor Yellow
aws ecr get-login-password --region $region | docker login --username AWS --password-stdin "$ecrUrl"
if ($LASTEXITCODE -ne 0) {
    Write-Host "Erreur d'authentification avec ECR." -ForegroundColor Red
    exit 1
}

Write-Host "Tag de l'image..." -ForegroundColor Yellow
docker tag django-polls:latest "$ecrUrl`:latest"

Write-Host "Push vers ECR..." -ForegroundColor Yellow
docker push "$ecrUrl`:latest"
if ($LASTEXITCODE -ne 0) {
    Write-Host "Erreur lors du push vers ECR." -ForegroundColor Red
    exit 1
}

Write-Host ""
Write-Host "=== Étape 6: Attente du démarrage de la tâche ECS ===" -ForegroundColor Cyan
Write-Host "Patience, la tâche ECS peut prendre 1-2 minutes pour démarrer..." -ForegroundColor Yellow
Start-Sleep -Seconds 30

Write-Host ""
Write-Host "=== Déploiement terminé! ===" -ForegroundColor Green
Write-Host ""
Write-Host "Pour récupérer l'IP publique de votre application:" -ForegroundColor Cyan
Write-Host "  .\get-ecs-task-ip.ps1" -ForegroundColor White
Write-Host ""

# Demander si on veut récupérer l'IP maintenant
$getIp = Read-Host "Récupérer l'IP publique maintenant? (y/n)"
if ($getIp -eq "y" -or $getIp -eq "Y") {
    Write-Host ""
    & ".\get-ecs-task-ip.ps1"
}
