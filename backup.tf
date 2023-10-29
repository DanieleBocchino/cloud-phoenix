#________________________ AWS Backup Vault ________________________

resource "aws_backup_vault" "phoenix_vault" {
  name = "phoenix-vault"
}

resource "aws_backup_plan" "phoenix_backup_plan" {
  name = "phoenix-backup-plan"

  rule {
    rule_name         = "phoenix-rule"
    target_vault_name = aws_backup_vault.phoenix_vault.name
    schedule          = "cron(0 12 * * ? *)"
  }
}

resource "aws_backup_selection" "phoenix_backup_selection" {
  iam_role_arn = aws_iam_role.phoenix_backup_role.arn
  name         = "phoenix-backup-selection"
  plan_id      = aws_backup_plan.phoenix_backup_plan.id

  resources = [
    aws_docdb_cluster.db_phoenix_cluster.arn,
  ]
}

#________________________ IAM Role per AWS Backup ________________________

resource "aws_iam_role" "phoenix_backup_role" {
  name = "phoenix-backup-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Action = "sts:AssumeRole",
        Effect = "Allow",
        Principal = {
          Service = "backup.amazonaws.com"
        }
      }
    ]
  })
}
