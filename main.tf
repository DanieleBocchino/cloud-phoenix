terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 2.0.0"
    }
  }
}

provider "aws" {
  region = var.aws_region
}

resource "aws_ecr_repository" "phoenix_repository" {
  name                 = "phoenix-repository"
  image_tag_mutability = "MUTABLE"
}

output "ecr_url" {
  value       = aws_ecr_repository.phoenix_repository.repository_url
  sensitive   = true
  description = "The URL of the ECR repository"
}

/* 
resource "null_resource" "build_and_push_docker_image" {

  triggers = {
    always_run = "${timestamp()}"
  }

  provisioner "local-exec" {
    command     = "./build_and_push_docker_image.sh"
    interpreter = ["/bin/bash", "-c"]

    environment = {
      AWS_DEFAULT_REGION = var.aws_region
      ECR_URL            = aws_ecr_repository.phoenix_repository.repository_url
    }
  }
} */
