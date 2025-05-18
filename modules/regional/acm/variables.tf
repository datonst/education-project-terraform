variable "domain_name" {
  type        = string
  description = "A domain name for which the certificate should be issued"
}

variable "tags" {
  type        = map(string)
  description = "Resource tags"
}
