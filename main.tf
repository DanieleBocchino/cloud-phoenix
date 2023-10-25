terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 2.0.0"
    }
  }
}

provider "aws" {
  region = "us-east-1"
}

resource "aws_ecr_repository" "phoenix_repository" {
  name                 = "phoenix-repository"
  image_tag_mutability = "MUTABLE"
}
