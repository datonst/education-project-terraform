variable "vpc_id" {
  type        = string
  description = "VPC ID"
}
variable "region" {
  type        = string
  description = "Region"
}
variable "route_table_ids" {
  type        = list(any)
  default     = []
  description = "Route Table"
}