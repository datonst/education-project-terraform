variable "prefix" {
  description = "Prefix for resource names"
  type        = string
}

variable "tags" {
  description = "Tags for resources"
  type        = map(string)
  default     = {}
}

variable "callback_urls" {
  description = "List of allowed callback URLs for the app clients"
  type        = list(string)
  default     = []
}

variable "logout_urls" {
  description = "List of allowed logout URLs for the app clients"
  type        = list(string)
  default     = []
}

variable "domain_prefix" {
  description = "Domain prefix for Cognito hosted UI"
  type        = string
}
