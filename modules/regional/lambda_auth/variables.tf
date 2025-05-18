variable "prefix" {
  description = "Prefix for resource names"
  type        = string
}

variable "tags" {
  description = "Tags for resources"
  type        = map(string)
  default     = {}
}

variable "s3_bucket_arn" {
  description = "ARN of the S3 bucket for file access"
  type        = string
}

variable "cognito_user_pool_arn" {
  description = "ARN of the Cognito User Pool"
  type        = string
}

variable "cognito_jwks_uri" {
  description = "JWKS URI for the Cognito User Pool"
  type        = string
}
