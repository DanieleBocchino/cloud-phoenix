resource "aws_ecr_repository" "phoenix_repository" {
  name                 = "phoenix-repository"
  image_tag_mutability = "MUTABLE"
}

output "ecr_url" {
  value       = aws_ecr_repository.phoenix_repository.repository_url
  sensitive   = true
  description = "The URL of the ECR repository"
}
