# Déploiement Django Polls sur Amazon ECS Fargate

## 🎯 Architecture déployée

```
┌─────────────────────────────────────────────────────────────┐
│                     Amazon Web Services                      │
│                                                               │
│  ┌────────────────────────────────────────────────────────┐ │
│  │                    VPC (10.0.0.0/16)                   │ │
│  │                                                        │ │
│  │  ┌──────────────────┐      ┌──────────────────┐      │ │
│  │  │  Public Subnet 1 │      │  Public Subnet 2 │      │ │
│  │  │   10.0.1.0/24    │      │   10.0.2.0/24    │      │ │
│  │  │   AZ: eu-west-1a │      │   AZ: eu-west-1b │      │ │
│  │  └────────┬─────────┘      └──────────────────┘      │ │
│  │           │                                            │ │
│  │           │  ┌────────────────────────────┐           │ │
│  │           └──│  ECS Fargate Task          │           │ │
│  │              │  - Container: Django       │           │ │
│  │              │  - Port: 8000              │           │ │
│  │              │  - CPU: 256                │           │ │
│  │              │  - Memory: 512 MB          │           │ │
│  │              │  - Public IP: Assigned     │           │ │
│  │              └────────────────────────────┘           │ │
│  │                                                        │ │
│  │  ┌────────────────────────────────────────────────┐  │ │
│  │  │        Security Group                          │  │ │
│  │  │  Inbound: Port 8000 (0.0.0.0/0)               │  │ │
│  │  │  Outbound: All traffic                        │  │ │
│  │  └────────────────────────────────────────────────┘  │ │
│  │                                                        │ │
│  │  ┌────────────────────────────────────────────────┐  │ │
│  │  │        Internet Gateway                        │  │ │
│  │  └────────────────────────────────────────────────┘  │ │
│  └────────────────────────────────────────────────────────┘ │
│                                                               │
│  ┌────────────────────────────────────────────────────────┐ │
│  │             ECS Cluster: django-polls-cluster         │ │
│  │  ┌──────────────────────────────────────────────────┐ │ │
│  │  │  Service: django-polls-service                   │ │ │
│  │  │  - Desired count: 1                              │ │ │
│  │  │  - Launch type: FARGATE                          │ │ │
│  │  │  - Task Definition: service:latest               │ │ │
│  │  └──────────────────────────────────────────────────┘ │ │
│  └────────────────────────────────────────────────────────┘ │
│                                                               │
│  ┌────────────────────────────────────────────────────────┐ │
│  │          ECR Repository: django-polls                  │ │
│  │          Image: latest (from Docker build)             │ │
│  └────────────────────────────────────────────────────────┘ │
└─────────────────────────────────────────────────────────────┘
```

## 📋 Ressources créées

### 1. **Réseau VPC**
- **VPC** : `10.0.0.0/16` avec DNS activé
- **2 Sous-réseaux publics** : Un dans chaque zone de disponibilité
  - Subnet 1 : `10.0.1.0/24` (AZ-1)
  - Subnet 2 : `10.0.2.0/24` (AZ-2)
- **Internet Gateway** : Pour l'accès Internet
- **Route Table** : Route `0.0.0.0/0` → Internet Gateway

### 2. **Sécurité**
- **Security Group** : `django-polls-ecs-tasks-sg`
  - Inbound : Port 8000 (HTTP) depuis `0.0.0.0/0`
  - Outbound : Tout le trafic autorisé

### 3. **ECS (Elastic Container Service)**
- **Cluster** : `django-polls-cluster` avec Container Insights
- **Task Definition** : `service`
  - Family: service
  - Requires: FARGATE
  - Network: awsvpc
  - CPU: 256 (0.25 vCPU)
  - Memory: 512 MB
  - Container: Django app sur port 8000
- **Service** : `django-polls-service`
  - Desired count: 1 tâche
  - Public IP: Oui
  - Launch type: FARGATE

### 4. **IAM**
- **Rôle** : `taskexec` (fourni par AWS)
  - Utilisé pour execution_role_arn et task_role_arn
  - Permet à ECS de pull l'image ECR
  - Permet l'écriture de logs CloudWatch

### 5. **ECR (déjà existant)**
- Repository pour l'image Django

## 🚀 Déploiement

### Option 1 : Script automatisé (recommandé)

```powershell
.\deploy-to-ecs.ps1
```

Ce script effectue automatiquement :
1. Vérification des prérequis
2. Construction de l'image Docker
3. Déploiement de l'infrastructure Terraform
4. Push de l'image vers ECR
5. Récupération de l'IP publique

### Option 2 : Déploiement manuel

#### Étape 1 : Construire l'image Docker
```powershell
docker build -t django-polls:latest .
```

#### Étape 2 : Initialiser Terraform
```powershell
terraform init
```

#### Étape 3 : Déployer l'infrastructure
```powershell
terraform plan
terraform apply
```

#### Étape 4 : Authentifier et pusher vers ECR
```powershell
$region = terraform output -raw aws_region
$ecrUrl = terraform output -raw ecr_repository_url

aws ecr get-login-password --region $region | docker login --username AWS --password-stdin $ecrUrl

docker tag django-polls:latest "$ecrUrl`:latest"
docker push "$ecrUrl`:latest"
```

#### Étape 5 : Attendre le démarrage (1-2 minutes)
```powershell
Start-Sleep -Seconds 60
```

#### Étape 6 : Récupérer l'IP publique
```powershell
.\get-ecs-task-ip.ps1
```

## 🔍 Récupération de l'IP publique

### Avec le script PowerShell
```powershell
.\get-ecs-task-ip.ps1
```

### Manuellement avec AWS CLI

```powershell
# 1. Récupérer le cluster et service
$cluster = terraform output -raw ecs_cluster_name
$service = terraform output -raw ecs_service_name
$region = terraform output -raw aws_region

# 2. Lister les tâches
$taskArn = aws ecs list-tasks --cluster $cluster --service-name $service --region $region --query 'taskArns[0]' --output text

# 3. Décrire la tâche pour obtenir l'ENI
$eniId = (aws ecs describe-tasks --cluster $cluster --tasks $taskArn --region $region --query 'tasks[0].attachments[0].details[?name==`networkInterfaceId`].value' --output text)

# 4. Obtenir l'IP publique depuis l'ENI
$publicIp = aws ec2 describe-network-interfaces --network-interface-ids $eniId --region $region --query 'NetworkInterfaces[0].Association.PublicIp' --output text

# 5. Afficher l'URL
Write-Host "http://$publicIp`:8000"
```

### Via la Console AWS

1. Allez sur https://console.aws.amazon.com/ecs/
2. Sélectionnez votre région (`eu-west-1`)
3. Cliquez sur le cluster `django-polls-cluster`
4. Cliquez sur le service `django-polls-service`
5. Onglet "Tasks" → Cliquez sur la tâche en cours
6. Section "Network" → Copiez l'**IP publique**
7. Ouvrez `http://<ip-publique>:8000` dans votre navigateur

## 📊 Vérification du déploiement

### Vérifier le cluster ECS
```powershell
aws ecs describe-clusters --clusters django-polls-cluster --region eu-west-1
```

### Vérifier le service
```powershell
aws ecs describe-services --cluster django-polls-cluster --services django-polls-service --region eu-west-1
```

### Vérifier les tâches en cours
```powershell
aws ecs list-tasks --cluster django-polls-cluster --service-name django-polls-service --region eu-west-1
```

### Voir les logs CloudWatch
```powershell
aws logs tail /ecs/django-polls --follow --region eu-west-1
```

## 🔧 Configuration détaillée

### Task Definition expliquée

```hcl
resource "aws_ecs_task_definition" "task_def" {
  family = "service"                      # Nom de la famille de tasks
  requires_compatibilities = ["FARGATE"]  # Mode serverless
  network_mode = "awsvpc"                 # Chaque tâche a sa propre ENI
  cpu = 256                               # 0.25 vCPU
  memory = 512                            # 512 MB RAM
  
  execution_role_arn = ...                # Rôle pour pull image + logs
  task_role_arn = ...                     # Rôle pour permissions app
  
  container_definitions = [...]           # Configuration du conteneur
}
```

**Pourquoi ces valeurs ?**
- **CPU: 256** = 0.25 vCPU (minimum pour Fargate)
- **Memory: 512 MB** = Suffisant pour Django en développement
- **network_mode: awsvpc** = Requis pour Fargate
- **Port 8000** = Port par défaut de Django

### Service ECS expliqué

```hcl
resource "aws_ecs_service" "main" {
  desired_count = 1                       # 1 instance de la tâche
  launch_type = "FARGATE"                 # Serverless (pas d'EC2 à gérer)
  
  network_configuration {
    subnets = [...]                       # Où déployer la tâche
    security_groups = [...]               # Règles de firewall
    assign_public_ip = true               # IP publique pour accès Internet
  }
}
```

**Pourquoi assign_public_ip = true ?**
- Permet à la tâche d'accéder à Internet (pull image ECR, etc.)
- Permet l'accès direct depuis Internet vers l'app
- En production, utiliseriez un Load Balancer

## 💰 Coûts estimés

### ECS Fargate
- **vCPU** : $0.04048/heure × 0.25 = ~$0.01/heure
- **Memory** : $0.004445/GB/heure × 0.5 GB = ~$0.002/heure
- **Total** : ~$0.012/heure = ~$8.64/mois (24/7)

### Autres coûts
- **ECR** : ~$0.07/mois (700 MB)
- **Data transfer** : Négligeable pour dev/test
- **CloudWatch Logs** : Gratuit (5 GB)

**Total estimé** : ~$9/mois si laissé tourner 24/7

💡 **Astuce** : Arrêtez le service quand vous ne l'utilisez pas :
```powershell
aws ecs update-service --cluster django-polls-cluster --service django-polls-service --desired-count 0 --region eu-west-1
```

## 🛠️ Dépannage

### La tâche ne démarre pas

**Vérifier les logs du service :**
```powershell
aws ecs describe-services --cluster django-polls-cluster --services django-polls-service --region eu-west-1 --query 'services[0].events[0:5]'
```

**Erreurs courantes :**
- Image non trouvée dans ECR → Vérifiez le push
- Erreur IAM → Vérifiez que le rôle `taskexec` existe
- Pas de sous-réseau disponible → Vérifiez le VPC/subnets

### Impossible d'accéder à l'application

1. **Vérifier que la tâche est RUNNING :**
```powershell
aws ecs list-tasks --cluster django-polls-cluster --desired-status RUNNING --region eu-west-1
```

2. **Vérifier le security group :**
   - Port 8000 ouvert sur `0.0.0.0/0` ?

3. **Vérifier l'IP publique :**
   - La tâche a bien une IP publique assignée ?

4. **Tester la connectivité :**
```powershell
Test-NetConnection -ComputerName <ip-publique> -Port 8000
```

### Les logs ne s'affichent pas

Le groupe de logs CloudWatch est créé automatiquement. Si problème :
```powershell
aws logs create-log-group --log-group-name /ecs/django-polls --region eu-west-1
```

## 🔄 Mise à jour de l'application

### 1. Modifier le code Django
### 2. Reconstruire l'image
```powershell
docker build -t django-polls:latest .
```

### 3. Pusher vers ECR
```powershell
$ecrUrl = terraform output -raw ecr_repository_url
docker tag django-polls:latest "$ecrUrl`:latest"
docker push "$ecrUrl`:latest"
```

### 4. Forcer le redéploiement
```powershell
aws ecs update-service --cluster django-polls-cluster --service django-polls-service --force-new-deployment --region eu-west-1
```

## 🧹 Nettoyage

### Supprimer toutes les ressources
```powershell
terraform destroy
```

Cela supprime :
- ✅ Service ECS
- ✅ Task Definition
- ✅ Cluster ECS
- ✅ VPC, Subnets, IGW, Routes
- ✅ Security Group
- ✅ Repository ECR

**Coût après suppression** : $0 !

## 📚 Ressources complémentaires

- [Documentation ECS Fargate](https://docs.aws.amazon.com/AmazonECS/latest/developerguide/AWS_Fargate.html)
- [Terraform AWS Provider - ECS](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/ecs_service)
- [Best Practices ECS](https://docs.aws.amazon.com/AmazonECS/latest/bestpracticesguide/intro.html)

## ✅ Checklist de déploiement

- [ ] Image Docker construite
- [ ] Image poussée vers ECR
- [ ] Infrastructure Terraform déployée
- [ ] Cluster ECS créé
- [ ] Service ECS en cours d'exécution
- [ ] Tâche ECS en état RUNNING
- [ ] IP publique récupérée
- [ ] Application accessible via HTTP
- [ ] Logs visibles dans CloudWatch

🎉 **Bravo !** Vous avez déployé Django sur ECS Fargate comme en production !
