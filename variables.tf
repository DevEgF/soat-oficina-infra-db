variable "aws_region" {
  description = "AWS region where the shared database is provisioned."
  type        = string
  default     = "us-east-1"

  validation {
    condition     = var.aws_region == "us-east-1"
    error_message = "This project is intentionally restricted to us-east-1."
  }
}

variable "state_bucket" {
  description = "S3 bucket that stores the shared Terraform states."
  type        = string

  validation {
    condition     = length(trimspace(var.state_bucket)) > 0
    error_message = "state_bucket must not be empty."
  }
}

variable "deletion_protection" {
  description = "Protect the shared RDS instance from accidental deletion."
  type        = bool
  default     = true
}
