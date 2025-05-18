variable "bucket" {
  type        = string
  description = "Name bucket S3"
}
variable "tags" {
  type        = map(string)
  description = "Tags S3"
}
variable "block_public_acls" {
  type        = bool
  description = "Block Public Access"
  default     = true
}
variable "block_public_policy" {
  type        = bool
  description = "Block Public Access"
  default     = true
}

variable "ignore_public_acls" {
  type        = bool
  description = "Ignore Public Access"
  default     = true
}
variable "restrict_public_buckets" {
  type        = bool
  description = "Restrict public buckets"
  default     = true
}
variable "enable_versioning" {
  type        = string
  description = "Enable Version for S3"
  default     = "Enabled"
}