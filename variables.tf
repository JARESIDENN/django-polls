variable "aws_region" {
  description = "Région AWS pour le déploiement"
  type        = string
  default     = "eu-west-1"
}

variable "ecr_repository_name" {
  description = "Nom du repository ECR"
  type        = string
  default     = "django-polls"
}

variable "environment" {
  description = "Environnement de déploiement"
  type        = string
  default     = "development"
}

variable "image_tag" {
  description = "Tag de l'image Docker"
  type        = string
  default     = "latest"
}
