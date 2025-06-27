variable "aws_access_key_id" {
  description = "AWS Access Key ID for backend services"
  type        = string
  sensitive   = true
}

variable "aws_secret_access_key" {
  description = "AWS Secret Access Key for backend services"
  type        = string
  sensitive   = true
}
