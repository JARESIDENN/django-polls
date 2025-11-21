# Outputs pour le conteneur local
output "container_id" {
  description = "ID du conteneur Django"
  value       = docker_container.django_polls_app.id
}

output "container_name" {
  description = "Nom du conteneur Django"
  value       = docker_container.django_polls_app.name
}

output "application_url" {
  description = "URL de l'application Django"
  value       = "http://localhost:8000"
}

output "image_id" {
  description = "ID de l'image Docker"
  value       = docker_image.django_polls.image_id
}

# Outputs pour ECR
output "ecr_repository_url" {
  description = "URL du repository ECR"
  value       = aws_ecr_repository.django_polls.repository_url
}

output "ecr_repository_arn" {
  description = "ARN du repository ECR"
  value       = aws_ecr_repository.django_polls.arn
}

output "ecr_image_uri" {
  description = "URI complète de l'image dans ECR"
  value       = "${aws_ecr_repository.django_polls.repository_url}:latest"
}

output "ecr_registry_id" {
  description = "ID du registry ECR"
  value       = aws_ecr_repository.django_polls.registry_id
}

# Outputs pour ECS
output "ecs_cluster_name" {
  description = "Nom du cluster ECS"
  value       = aws_ecs_cluster.main.name
}

output "ecs_cluster_id" {
  description = "ID du cluster ECS"
  value       = aws_ecs_cluster.main.id
}

output "ecs_service_name" {
  description = "Nom du service ECS"
  value       = aws_ecs_service.main.name
}

output "vpc_id" {
  description = "ID du VPC"
  value       = aws_vpc.main.id
}

output "public_subnet_ids" {
  description = "IDs des sous-réseaux publics"
  value       = [for subnet in aws_subnet.public : subnet.id]
}

output "security_group_id" {
  description = "ID du security group ECS"
  value       = aws_security_group.ecs_tasks.id
}

output "task_definition_arn" {
  description = "ARN de la task definition"
  value       = aws_ecs_task_definition.task_def.arn
}

output "ecs_console_url" {
  description = "URL de la console ECS pour voir les tâches"
  value       = "https://${var.aws_region}.console.aws.amazon.com/ecs/v2/clusters/${aws_ecs_cluster.main.name}/services/${aws_ecs_service.main.name}/tasks"
}

output "aws_region" {
  description = "Région AWS utilisée"
  value       = var.aws_region
}
