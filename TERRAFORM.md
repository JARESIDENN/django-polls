# Déploiement Django avec Terraform et Docker

## Architecture
Ce projet utilise **Terraform** avec le provider **Docker** pour orchestrer le build et le déploiement de l'application Django en local.

## Fichiers Terraform
- `main.tf` : Configuration principale (provider Docker, image et conteneur)
- `outputs.tf` : Sorties affichées après le déploiement

## Prérequis
- Docker Desktop installé et démarré
- Terraform installé
- PowerShell (Windows)

## Commandes Terraform

### Initialiser Terraform
```powershell
& "C:\Program Files\Terraform\terraform.exe" init
```

### Construire l'image Docker
```powershell
docker build -t django-polls:latest .
```

### Planifier le déploiement
```powershell
& "C:\Program Files\Terraform\terraform.exe" plan
```

### Appliquer le déploiement
```powershell
& "C:\Program Files\Terraform\terraform.exe" apply -auto-approve
```

### Détruire l'infrastructure
```powershell
& "C:\Program Files\Terraform\terraform.exe" destroy -auto-approve
```

## Accès à l'application
Une fois déployé, l'application est accessible sur : **http://localhost:8000**

## État de l'infrastructure
Pour voir l'état actuel :
```powershell
& "C:\Program Files\Terraform\terraform.exe" show
```

## Vérification du conteneur
```powershell
# Voir les conteneurs en cours
docker ps

# Voir les logs
docker logs django-polls-app

# Voir les logs en temps réel
docker logs -f django-polls-app
```

## Ressources créées par Terraform
- **Image Docker** : `django-polls:latest`
- **Conteneur** : `django-polls-app`
- **Port exposé** : 8000

## Configuration
Le conteneur est configuré avec :
- Politique de redémarrage : `unless-stopped`
- Port mapping : 8000:8000
- Base de données : SQLite (dans le conteneur)
