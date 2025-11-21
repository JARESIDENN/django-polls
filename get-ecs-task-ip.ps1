# Script pour récupérer l'IP publique de la tâche ECS Django
# Usage: .\get-ecs-task-ip.ps1

Write-Host "=== Récupération de l'IP publique de la tâche ECS ===" -ForegroundColor Cyan
Write-Host ""

# Récupérer les informations depuis Terraform
$clusterName = terraform output -raw ecs_cluster_name 2>$null
$serviceName = terraform output -raw ecs_service_name 2>$null
$region = terraform output -raw aws_region 2>$null

if (-not $clusterName -or -not $serviceName) {
    Write-Host "Erreur: Impossible de récupérer les informations depuis Terraform." -ForegroundColor Red
    Write-Host "Assurez-vous d'avoir exécuté 'terraform apply' avec succès." -ForegroundColor Yellow
    exit 1
}

Write-Host "Cluster: $clusterName" -ForegroundColor Gray
Write-Host "Service: $serviceName" -ForegroundColor Gray
Write-Host "Région: $region" -ForegroundColor Gray
Write-Host ""

# Récupérer l'ARN de la tâche
Write-Host "Récupération de l'ARN de la tâche..." -ForegroundColor Yellow
$taskArns = aws ecs list-tasks --cluster $clusterName --service-name $serviceName --region $region --query 'taskArns[0]' --output text

if (-not $taskArns -or $taskArns -eq "None") {
    Write-Host "Aucune tâche en cours d'exécution trouvée." -ForegroundColor Red
    Write-Host "Vérifiez que le service ECS est démarré correctement." -ForegroundColor Yellow
    exit 1
}

Write-Host "✓ Tâche trouvée: $taskArns" -ForegroundColor Green
Write-Host ""

# Récupérer les détails de la tâche
Write-Host "Récupération des détails de la tâche..." -ForegroundColor Yellow
$taskDetails = aws ecs describe-tasks --cluster $clusterName --tasks $taskArns --region $region --output json | ConvertFrom-Json

# Extraire l'ENI (Elastic Network Interface)
$eniId = $taskDetails.tasks[0].attachments[0].details | Where-Object { $_.name -eq "networkInterfaceId" } | Select-Object -ExpandProperty value

if (-not $eniId) {
    Write-Host "Impossible de trouver l'interface réseau de la tâche." -ForegroundColor Red
    exit 1
}

Write-Host "✓ Interface réseau: $eniId" -ForegroundColor Green
Write-Host ""

# Récupérer l'IP publique depuis l'ENI
Write-Host "Récupération de l'IP publique..." -ForegroundColor Yellow
$publicIp = aws ec2 describe-network-interfaces --network-interface-ids $eniId --region $region --query 'NetworkInterfaces[0].Association.PublicIp' --output text

if (-not $publicIp -or $publicIp -eq "None") {
    Write-Host "Aucune IP publique trouvée pour cette tâche." -ForegroundColor Red
    Write-Host "La tâche est peut-être encore en cours de démarrage." -ForegroundColor Yellow
    exit 1
}

Write-Host ""
Write-Host "=== Tâche ECS déployée avec succès! ===" -ForegroundColor Green
Write-Host ""
Write-Host "IP Publique: " -NoNewline -ForegroundColor Cyan
Write-Host $publicIp -ForegroundColor White
Write-Host ""
Write-Host "URL de l'application: " -NoNewline -ForegroundColor Cyan
Write-Host "http://$publicIp`:8000" -ForegroundColor White
Write-Host ""
Write-Host "Statut de la tâche: " -NoNewline -ForegroundColor Cyan
Write-Host $taskDetails.tasks[0].lastStatus -ForegroundColor White
Write-Host ""

# Ouvrir dans le navigateur
$openBrowser = Read-Host "Voulez-vous ouvrir l'application dans le navigateur? (y/n)"
if ($openBrowser -eq "y" -or $openBrowser -eq "Y") {
    Start-Process "http://$publicIp`:8000"
}

Write-Host ""
Write-Host "Console ECS: https://$region.console.aws.amazon.com/ecs/v2/clusters/$clusterName/services/$serviceName/tasks" -ForegroundColor Gray
