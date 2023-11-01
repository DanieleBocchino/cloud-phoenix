# ________ MAIN _____

variable "aws_region" {
  description = "AWS region"
  default     = "us-east-1"
}

variable "aws_account_id" {
  description = "AWS account ID"
  default     = ""
}

variable "github_oauthtoken" {
  description = "GitHub OAuth token"
  default     = ""
}


variable "email" {
  description = "Email address for CPU utilization alerts"
  type        = string
  default     = ""
}

variable "port" {
  description = "Port for the application"
  type        = number
  default     = 3000
}


# _____ DOCUMENT DB _____

variable "db_password" {
  description = "The password for the DocumentDB"
  default     = ""
}

variable "db_username" {
  description = "The username for the DocumentDB"
  default     = ""
}

variable "db_name" {
  description = "The name of the DocumentDB"
  default     = ""
}