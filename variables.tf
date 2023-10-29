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

variable "github_repository_url" {
  description = "GitHub repository URL"
  default     = "https://github.com/DanieleBocchino/claranet-finale.git"
}


variable "alert_email" {
  description = "Email address for CPU utilization alerts"
  type        = string
  default     = "bocchino.daniele@gmail.com"
}


# _______ NODE _______

variable "application_port" {
  description = "The port the application will listen on"
  default     = 3000
}

# _____ Mongo DB _____

variable "db_password" {
  description = "The password for the DocumentDB"
  default     = ""
}

variable "db_username" {
  description = "The username for the DocumentDB"
  default     = ""
}
