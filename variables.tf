variable "alert_email" {
  description = "Email address for CPU utilization alerts"
  type        = string
  default     = "bocchino.daniele@gmail.com"
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
