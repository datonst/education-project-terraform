variable "lb_name" {
  type    = string
  default = "lb_name"
}

variable "subnet_ids" {
  type    = list(any)
  default = []
}

variable "security_group_ids" {
  type    = list(any)
  default = []
}

variable "cluster_name" {
  type    = string
  default = "cluster_name"
}

variable "common_tags" {
  type    = map(string)
  default = {}
}

variable "internal" {
  type    = bool
  default = true
}

variable "load_balancer_type" {
  type    = string
  default = "network"
}
