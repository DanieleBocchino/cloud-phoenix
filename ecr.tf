
# __________________________________________________ ECR __________________________________________________

resource "aws_ecr_repository" "phoenix_repository" {
  name                 = "cloud-phoenix-repository"
  image_tag_mutability = "MUTABLE"

  image_scanning_configuration {
    scan_on_push = true
  }
}

output "repository_url" {
  value = aws_ecr_repository.phoenix_repository.repository_url
}