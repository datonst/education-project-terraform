variable "parameters" {
  description = "Map of SSM parameters to create"
  type = map(object({
    type        = string
    value       = string
    description = optional(string)
    key_id      = optional(string)
  }))
  default = {}
}

variable "tags" {
  description = "A map of tags to add to all resources"
  type        = map(string)
  default     = {}
}
