# Script de déploiement automatisé pour Django Polls sur ECR
# Utilisation: .\deploy-to-ecr.ps1

Write-Host "=== Déploiement Django Polls vers Amazon ECR ===" -ForegroundColor Cyan
Write-Host ""

# Vérifier que Docker est en cours d'exécution
Write-Host "Vérification de Docker..." -ForegroundColor Yellow
try {
    docker info > $null 2>&1
    if ($LASTEXITCODE -ne 0) {
        Write-Host "Erreur: Docker n'est pas en cours d'exécution. Démarrez Docker Desktop." -ForegroundColor Red
        exit 1
    }
    Write-Host "✓ Docker est actif" -ForegroundColor Green
} catch {
    Write-Host "Erreur: Docker n'est pas installé ou n'est pas accessible." -ForegroundColor Red
    exit 1
}

# Vérifier AWS CLI
Write-Host "Vérification d'AWS CLI..." -ForegroundColor Yellow
try {
    aws --version > $null 2>&1
    if ($LASTEXITCODE -ne 0) {
        Write-Host "Erreur: AWS CLI n'est pas installé." -ForegroundColor Red
        Write-Host "Installez-le depuis: https://aws.amazon.com/cli/" -ForegroundColor Yellow
        exit 1
    }
    Write-Host "✓ AWS CLI est installé" -ForegroundColor Green
} catch {
    Write-Host "Erreur: AWS CLI n'est pas accessible." -ForegroundColor Red
    exit 1
}

# Vérifier les credentials AWS
Write-Host "Vérification des credentials AWS..." -ForegroundColor Yellow
try {
    $identity = aws sts get-caller-identity 2>&1
    if ($LASTEXITCODE -ne 0) {
        Write-Host "Erreur: Credentials AWS non configurés." -ForegroundColor Red
        Write-Host "Exécutez: aws configure" -ForegroundColor Yellow
        exit 1
    }
    Write-Host "✓ Credentials AWS configurés" -ForegroundColor Green
    Write-Host "  Compte AWS: $($identity | ConvertFrom-Json | Select-Object -ExpandProperty Account)" -ForegroundColor Gray
} catch {
    Write-Host "Erreur lors de la vérification des credentials AWS." -ForegroundColor Red
    exit 1
}

# Vérifier Terraform
Write-Host "Vérification de Terraform..." -ForegroundColor Yellow
try {
    terraform version > $null 2>&1
    if ($LASTEXITCODE -ne 0) {
        Write-Host "Erreur: Terraform n'est pas installé." -ForegroundColor Red
        Write-Host "Installez-le depuis: https://www.terraform.io/downloads" -ForegroundColor Yellow
        exit 1
    }
    Write-Host "✓ Terraform est installé" -ForegroundColor Green
} catch {
    Write-Host "Erreur: Terraform n'est pas accessible." -ForegroundColor Red
    exit 1
}

Write-Host ""
Write-Host "=== Tous les prérequis sont satisfaits ===" -ForegroundColor Green
Write-Host ""

# Initialiser Terraform
Write-Host "Initialisation de Terraform..." -ForegroundColor Cyan
terraform init
if ($LASTEXITCODE -ne 0) {
    Write-Host "Erreur lors de l'initialisation de Terraform." -ForegroundColor Red
    exit 1
}

Write-Host ""
Write-Host "=== Plan Terraform ===" -ForegroundColor Cyan
terraform plan

Write-Host ""
$confirm = Read-Host "Voulez-vous appliquer cette configuration? (yes/no)"
if ($confirm -ne "yes") {
    Write-Host "Déploiement annulé." -ForegroundColor Yellow
    exit 0
}

# Appliquer la configuration
Write-Host ""
Write-Host "=== Application de la configuration ===" -ForegroundColor Cyan
terraform apply -auto-approve

if ($LASTEXITCODE -eq 0) {
    Write-Host ""
    Write-Host "=== Déploiement réussi! ===" -ForegroundColor Green
    Write-Host ""
    Write-Host "Outputs:" -ForegroundColor Cyan
    terraform output
    
    Write-Host ""
    Write-Host "Votre image Django Polls a été déployée sur Amazon ECR!" -ForegroundColor Green
    Write-Host "Consultez le fichier TERRAFORM_ECR.md pour plus d'informations." -ForegroundColor Yellow
} else {
    Write-Host ""
    Write-Host "=== Erreur lors du déploiement ===" -ForegroundColor Red
    Write-Host "Consultez les messages d'erreur ci-dessus pour plus de détails." -ForegroundColor Yellow
    exit 1
}
