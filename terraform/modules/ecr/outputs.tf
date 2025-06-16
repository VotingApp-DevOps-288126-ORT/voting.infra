output "repository_url" {
  description = "URL completa del ECR"
  value       = aws_ecr_repository.elastic_container_registry.repository_url
}
