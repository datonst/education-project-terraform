variable "regional_domain_name" {
  type        = string
  description = "Regional domain name for ALB origin"
}

variable "comment" {
  type    = string
  default = ""
}

variable "root" {
  type    = string
  default = "index.html"
}

variable "domain_names" {
  description = "Domain names for CloudFront distribution"
  type        = list(string)
  default     = []
}

variable "tags" {
  description = "Tags for CloudFront distribution"
  type        = map(string)
  default     = {}
}

variable "acm_certificate_arn" {
  description = "ACM certificate ARN for CloudFront distribution"
  type        = string
  default     = null
}

variable "s3_bucket_arn" {
  description = "S3 bucket ARN for bucket policy"
  type        = string
}

variable "s3_bucket_domain_name" {
  description = "S3 bucket domain name for S3 origin"
  type        = string
}

variable "s3_bucket_id" {
  description = "S3 bucket ID for bucket policy"
  type        = string
}

variable "origin_id" {
  description = "Origin ID prefix for CloudFront origins"
  type        = string
}

variable "web_acl_id" {
  description = "Web ACL ID for CloudFront distribution"
  type        = string
  default     = null
}

variable "cloudfront_default_certificate" {
  description = "Whether to use CloudFront default certificate"
  type        = bool
  default     = true
}

variable "ssl_support_method" {
  description = "SSL support method for CloudFront distribution"
  type        = string
  default     = null
}

variable "custom_error_response" {
  description = "Custom error response for CloudFront distribution"
  type = list(object({
    error_caching_min_ttl = number
    error_code            = number
    response_code         = number
    response_page_path    = string
  }))
  default = []
}

# Lambda@Edge variables for secure content access and user authentication
variable "auth_lambda_arn" {
  description = "ARN of Lambda@Edge function for authentication (with version)"
  type        = string
  default     = null
}


