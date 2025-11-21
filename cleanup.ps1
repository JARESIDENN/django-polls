# Script de nettoyage des ressources AWS ECR et Terraform
# Utilisation: .\cleanup.ps1

Write-Host "=== Nettoyage des ressources Django Polls ===" -ForegroundColor Cyan
Write-Host ""

$confirm = Read-Host "Êtes-vous sûr de vouloir supprimer toutes les ressources? (yes/no)"
if ($confirm -ne "yes") {
    Write-Host "Nettoyage annulé." -ForegroundColor Yellow
    exit 0
}

Write-Host ""
Write-Host "Destruction des ressources Terraform..." -ForegroundColor Yellow
terraform destroy -auto-approve

if ($LASTEXITCODE -eq 0) {
    Write-Host ""
    Write-Host "✓ Ressources Terraform supprimées" -ForegroundColor Green
} else {
    Write-Host ""
    Write-Host "Erreur lors de la destruction des ressources." -ForegroundColor Red
    exit 1
}

Write-Host ""
Write-Host "=== Nettoyage terminé ===" -ForegroundColor Green
