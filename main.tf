terraform {
  required_providers {
    docker = {
      source  = "kreuzwerker/docker"
      version = "~> 3.0"
    }
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "docker" {
  host = "npipe:////./pipe/docker_engine"
}

provider "aws" {
  region = var.aws_region
}

# Création du repository ECR
resource "aws_ecr_repository" "django_polls" {
  name                 = var.ecr_repository_name
  image_tag_mutability = "MUTABLE"

  image_scanning_configuration {
    scan_on_push = true
  }

  tags = {
    Name        = var.ecr_repository_name
    Environment = var.environment
  }
}

# Politique de cycle de vie pour limiter le nombre d'images
resource "aws_ecr_lifecycle_policy" "django_polls" {
  repository = aws_ecr_repository.django_polls.name

  policy = jsonencode({
    rules = [{
      rulePriority = 1
      description  = "Conserver les 5 dernières images"
      selection = {
        tagStatus   = "any"
        countType   = "imageCountMoreThan"
        countNumber = 5
      }
      action = {
        type = "expire"
      }
    }]
  })
}

# Obtenir le token d'authentification ECR
data "aws_ecr_authorization_token" "token" {}

# Référencer l'image Docker (déjà construite)
resource "docker_image" "django_polls" {
  name         = "django-polls:latest"
  keep_locally = true
}

# Tagger l'image pour ECR (pour push manuel)
resource "docker_tag" "django_polls_ecr" {
  source_image = docker_image.django_polls.name
  target_image = "${aws_ecr_repository.django_polls.repository_url}:${var.image_tag}"
}

# Note: Le push vers ECR doit être fait manuellement avec:
# aws ecr get-login-password --region <region> | docker login --username AWS --password-stdin <ecr-url>
# docker push <ecr-url>:latest

# Déploiement du conteneur local (optionnel)
resource "docker_container" "django_polls_app" {
  name  = "django-polls-app"
  image = docker_image.django_polls.image_id

  ports {
    internal = 8000
    external = 8000
  }

  restart = "unless-stopped"
}

# ============================================
# INFRASTRUCTURE RÉSEAU POUR ECS
# ============================================

# Récupérer les zones de disponibilité
data "aws_availability_zones" "available" {
  state = "available"
}

# VPC pour ECS
resource "aws_vpc" "main" {
  cidr_block           = "10.0.0.0/16"
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = {
    Name        = "django-polls-vpc"
    Environment = var.environment
  }
}

# Internet Gateway pour accès Internet
resource "aws_internet_gateway" "main" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name        = "django-polls-igw"
    Environment = var.environment
  }
}

# Sous-réseaux publics (2 pour haute disponibilité) - Utilisation de for_each
resource "aws_subnet" "public" {
  for_each = {
    "subnet-1" = {
      cidr_block        = "10.0.0.0/24"
      availability_zone = data.aws_availability_zones.available.names[0]
    }
    "subnet-2" = {
      cidr_block        = "10.0.1.0/24"
      availability_zone = data.aws_availability_zones.available.names[1]
    }
  }

  vpc_id                  = aws_vpc.main.id
  cidr_block              = each.value.cidr_block
  availability_zone       = each.value.availability_zone
  map_public_ip_on_launch = true

  tags = {
    Name        = "django-polls-${each.key}"
    Environment = var.environment
  }
}

# Table de routage pour sous-réseaux publics
resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.main.id
  }

  tags = {
    Name        = "django-polls-public-rt"
    Environment = var.environment
  }
}

# Association des sous-réseaux à la table de routage - Utilisation de for_each
resource "aws_route_table_association" "public" {
  for_each = aws_subnet.public

  subnet_id      = each.value.id
  route_table_id = aws_route_table.public.id
}

# Security Group pour ECS tasks
resource "aws_security_group" "ecs_tasks" {
  name        = "django-polls-ecs-tasks-sg"
  description = "Security group for Django ECS tasks"
  vpc_id      = aws_vpc.main.id

  # Autoriser le trafic HTTP entrant sur le port 8000
  ingress {
    description = "HTTP from anywhere"
    from_port   = 8000
    to_port     = 8000
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # Autoriser tout le trafic sortant
  egress {
    description = "Allow all outbound traffic"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name        = "django-polls-ecs-sg"
    Environment = var.environment
  }
}

# ============================================
# DATA SOURCES
# ============================================

# Récupérer le rôle IAM pour l'exécution des tâches
data "aws_iam_role" "task_exec" {
  name = "taskexec"
}

# Récupérer les informations de l'image ECR
data "aws_ecr_image" "image" {
  repository_name = aws_ecr_repository.django_polls.name
  image_tag       = var.image_tag
}

# ============================================
# ECS CLUSTER
# ============================================

resource "aws_ecs_cluster" "main" {
  name = "django-polls-cluster"

  setting {
    name  = "containerInsights"
    value = "enabled"
  }

  tags = {
    Name        = "django-polls-cluster"
    Environment = var.environment
  }
}

# ============================================
# ECS TASK DEFINITION
# ============================================

resource "aws_ecs_task_definition" "task_def" {
  family                   = "service"
  requires_compatibilities = ["FARGATE"]
  network_mode             = "awsvpc"
  cpu                      = 256
  memory                   = 512
  execution_role_arn       = data.aws_iam_role.task_exec.arn
  task_role_arn            = data.aws_iam_role.task_exec.arn

  container_definitions = jsonencode([
    {
      name               = "first"
      image              = "${aws_ecr_repository.django_polls.repository_url}:${var.image_tag}"
      essential          = true
      cpu                = 256
      memory_reservation = 512
      portMappings = [
        {
          containerPort = 8000
          hostPort      = 8000
          protocol      = "tcp"
        }
      ]
      logConfiguration = {
        logDriver = "awslogs"
        options = {
          "awslogs-group"         = "/ecs/django-polls"
          "awslogs-region"        = var.aws_region
          "awslogs-stream-prefix" = "ecs"
        }
      }
      environment = [
        {
          name  = "DJANGO_SETTINGS_MODULE"
          value = "mysite.settings"
        }
      ]
    }
  ])

  tags = {
    Name        = "django-polls-task"
    Environment = var.environment
  }
}

# ============================================
# ECS SERVICE
# ============================================

resource "aws_ecs_service" "main" {
  name            = "django-polls-service"
  cluster         = aws_ecs_cluster.main.id
  task_definition = aws_ecs_task_definition.task_def.arn
  desired_count   = 1
  launch_type     = "FARGATE"

  network_configuration {
    subnets          = [for subnet in aws_subnet.public : subnet.id]
    security_groups  = [aws_security_group.ecs_tasks.id]
    assign_public_ip = true
  }

  tags = {
    Name        = "django-polls-service"
    Environment = var.environment
  }

  depends_on = [
    aws_internet_gateway.main,
    aws_route_table_association.public
  ]
}
