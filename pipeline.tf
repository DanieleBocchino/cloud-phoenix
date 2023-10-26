


# S3 Bucket for CodePipeline artifacts
resource "aws_s3_bucket" "codepipeline_bucket" {
  bucket = "phoenix-codepipeline-bucket"
  acl    = "private"
}


resource "aws_codecommit_repository" "phoenix_repository" {
  repository_name = "phoenix-commit-repository"
  description     = "Code repository for the Phoenix application"
}


# CodeBuild Project
resource "aws_codebuild_project" "phoenix_codebuild" {
  name          = "phoenix-build"
  build_timeout = "5"
  service_role  = aws_iam_role.codebuild_role.arn

  artifacts {
    type = "CODEPIPELINE"
  }

  environment {
    compute_type    = "BUILD_GENERAL1_SMALL"
    image           = "aws/codebuild/standard:4.0"
    type            = "LINUX_CONTAINER"
    privileged_mode = true

    environment_variable {
      name  = "AWS_DEFAULT_REGION"
      value = var.aws_region
    }

    environment_variable {
      name  = "ECR_URL"
      value = aws_ecr_repository.phoenix_repository.repository_url
    }

  }

  source {
    type      = "CODEPIPELINE"
    buildspec = file("buildspec.yaml")
  }
}

# CodePipeline
resource "aws_codepipeline" "phoenix_codepipeline" {
  name     = "phoenix-pipeline"
  role_arn = aws_iam_role.codepipeline_role.arn

  artifact_store {
    location = aws_s3_bucket.codepipeline_bucket.bucket
    type     = "S3"
  }

  stage {
    name = "Source"

    action {
      name             = "SourceAction"
      category         = "Source"
      owner            = "ThirdParty"
      provider         = "GitHub"
      version          = "1"
      output_artifacts = ["source_output"]

      configuration = {
        Owner      = "DanieleBocchino"
        Repo       = "cloud-phoenix"
        Branch     = "master"                
        OAuthToken = var.github_oauthtoken 
      }
    }
  }

  stage {
    name = "Build"

    action {
      name             = "BuildAction"
      category         = "Build"
      owner            = "AWS"
      provider         = "CodeBuild"
      input_artifacts  = ["source_output"]
      output_artifacts = ["build_output"]
      version          = "1"

      configuration = {
        ProjectName = aws_codebuild_project.phoenix_codebuild.name
      }
    }
  }

  stage {
    name = "Deploy"

    action {
      name            = "DeployAction"
      category        = "Deploy"
      owner           = "AWS"
      provider        = "ECS"
      input_artifacts = ["build_output"]
      version         = "1"

      configuration = {
        ClusterName = aws_ecs_cluster.phoenix_cluster.name
        ServiceName = aws_ecs_service.phoenix_service.name
        FileName    = "imagedefinitions.json"
      }
    }
  }
}

# __ POLICY __

# IAM Role for CodeBuild
resource "aws_iam_role" "codebuild_role" {
  name = "codebuild-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Action = "sts:AssumeRole",
        Effect = "Allow",
        Principal = {
          Service = "codebuild.amazonaws.com"
        }
      }
    ]
  })
}

# IAM Role for CodePipeline
resource "aws_iam_role" "codepipeline_role" {
  name = "codepipeline-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Action = "sts:AssumeRole",
        Effect = "Allow",
        Principal = {
          Service = "codepipeline.amazonaws.com"
        }
      }
    ]
  })
}
resource "aws_iam_role_policy" "codebuild_policy" {
  role = "${aws_iam_role.codebuild_role.name}"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action   = "*"
        Effect   = "Allow"
        Resource = "*"
      },
    ]  
  })
}

resource "aws_iam_role_policy" "codepipeline_policy" {
  role = "${aws_iam_role.codepipeline_role.name}"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action   = "*"
        Effect   = "Allow"
        Resource = "*"
      },
    ]  
  })
}


/* 


resource "aws_iam_policy" "codepipeline_codecommit_policy" {
  name        = "codepipeline-codecommit-access"
  description = "Policy to allow CodePipeline to access CodeCommit"

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow",
        Action = [
          "codecommit:GitPull",
          "codecommit:Get*",
          "codecommit:List*"
        ],
        Resource = [
          "arn:aws:codecommit:${var.aws_region}:${var.aws_account_id}:phoenix-commit-repository"
        ]
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "codepipeline_codecommit_policy_attach" {
  role       = aws_iam_role.codepipeline_role.name
  policy_arn = aws_iam_policy.codepipeline_codecommit_policy.arn
}


resource "aws_iam_policy" "codepipeline_s3_access" {
  name        = "codepipeline-s3-access"
  description = "Policy to allow CodePipeline to access S3"

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow",
        Action = [
          "s3:GetObject",
          "s3:PutObject",
          "s3:ListBucket"
        ],
        Resource = [
          "arn:aws:s3:::phoenix-codepipeline-bucket",
          "arn:aws:s3:::phoenix-codepipeline-bucket/*"
        ]
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "codepipeline_s3_access_attach" {
  role       = aws_iam_role.codepipeline_role.name
  policy_arn = aws_iam_policy.codepipeline_s3_access.arn
}


resource "aws_iam_policy" "codepipeline_codebuild_startbuild" {
  name        = "codepipeline-codebuild-startbuild"
  description = "Policy to allow CodePipeline to start a CodeBuild"

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow",
        Action = [
          "codebuild:StartBuild"
        ],
        Resource = [
          "arn:aws:codebuild:us-east-1:324807847207:project/phoenix-build"
        ]
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "codepipeline_codebuild_startbuild_attach" {
  role       = aws_iam_role.codepipeline_role.name
  policy_arn = aws_iam_policy.codepipeline_codebuild_startbuild.arn
}


resource "aws_iam_policy" "codepipeline_extended_permissions" {
  name        = "codepipeline-extended-permissions"
  description = "Extended permissions for CodePipeline"

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow",
        Action = [
          "codebuild:StartBuild",
          "codebuild:BatchGetBuilds"
        ],
        Resource = [
          "arn:aws:codebuild:us-east-1:324807847207:project/phoenix-build"
        ]
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "codepipeline_extended_permissions_attach" {
  role       = aws_iam_role.codepipeline_role.name
  policy_arn = aws_iam_policy.codepipeline_extended_permissions.arn
}


resource "aws_iam_policy" "codepipeline_full_ecs_permissions" {
  name        = "codepipeline-full-ecs-permissions"
  description = "Full permissions for ECS in CodePipeline"

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow",
        Action = "ecs:*",
        Resource = "*"
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "codepipeline_full_ecs_permissions_attach" {
  role       = aws_iam_role.codepipeline_role.name
  policy_arn = aws_iam_policy.codepipeline_full_ecs_permissions.arn
}
 */