resource "aws_s3_bucket" "phoenix_mongodb_backup" {
  bucket = "phoenix-mongodb-backup-bucket"
  acl    = "private"
  force_destroy = true
}

resource "aws_backup_vault" "backup_vault" {
  name = "mongodb-backup-vault"
}

resource "aws_backup_plan" "backup_plan" {
  name = "mongodb-backup-plan"

  rule {
    rule_name         = "daily-backup-rule"
    target_vault_name = aws_backup_vault.backup_vault.name
    schedule          = "cron(0 12 * * ? *)"

    lifecycle {
      delete_after = "7"
    }
  }
}

resource "aws_backup_selection" "backup_selection" {
  name     = "mongodb-backup-selection"
  plan_id  = aws_backup_plan.backup_plan.id  
  iam_role_arn = aws_iam_role.aws_backup_role.arn  
  resources = [
    aws_s3_bucket.phoenix_mongodb_backup.arn
  ]
}


resource "aws_iam_role" "aws_backup_role" {
  name = "aws-backup-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Action = "sts:AssumeRole",
        Principal = {
          Service = "backup.amazonaws.com"
        },
        Effect = "Allow",
      }
    ]
  })
}

resource "aws_iam_role_policy" "aws_backup_policy" {
  name = "aws-backup-policy"
  role = aws_iam_role.aws_backup_role.id

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Action = [
          "s3:GetBucketLocation",
          "s3:GetObject",
          "s3:ListBucket",
          "s3:PutObject"
        ],
        Resource = [
          aws_s3_bucket.phoenix_mongodb_backup.arn,
          "${aws_s3_bucket.phoenix_mongodb_backup.arn}/*"
        ],
        Effect = "Allow"
      }
    ]
  })
}
