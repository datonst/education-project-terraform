variable "name" {
  type        = string
  default     = "EC2"
  description = "EC2 name"
}

variable "iam_role_name" {
  description = "The IAM role to assign to the instance"
  type        = string
  default     = ""
}

variable "subnet_id" {
  type = string
}

variable "vpc_id" {
  type = string
}

variable "associate_public_ip_address" {
  description = "Associate a public IP address with an instance in a VPC"
  type        = bool
  default     = null
}

variable "private_ip" {
  type    = string
  default = null
}

variable "instance_type" {
  type        = list(any)
  default     = ["t3.medium"]
  description = "EC2 - instance type"
}

variable "ec2_ips" {
  type        = list(any)
  description = "EC2 - Private IP"
  default     = []
}

variable "volume_size" {
  type        = list(any)
  default     = ["10"]
  description = "Size of the volume in gibibytes (GiB)"
}

variable "vpc_security_group_ids" {
  type    = list(any)
  default = []
}

variable "ami_id" {
  type = string
}

variable "user_data" {
  type    = string
  default = null # default = "./scripts/turn-on-pw.sh"
}

variable "key_name" {
  description = "Key name of the Key Pair to use for the instance"
  type        = string
  default     = null
}

variable "ebs_optimized" {
  description = "EBS-optimized"
  type        = bool
  default     = null
}

variable "ebs_volume_count" {
  type    = number
  default = 0
}

variable "availability_zone" {
  type    = string
  default = ""
}

variable "ebs_volume_type" {
  type    = string
  default = "gp2"
}

variable "ebs_volume_size" {
  type    = number
  default = 10
}

variable "root_throughput" {
  type    = number
  default = 0
}

variable "ebs_volume_encrypted" {
  type    = bool
  default = true
}

variable "ebs_device_name" {
  type    = list(string)
  default = ["/dev/xvdb", "/dev/xvdc", "/dev/xvdd", "/dev/xvde", "/dev/xvdf", "/dev/xvdg", "/dev/xvdh", "/dev/xvdi", "/dev/xvdj", "/dev/xvdk", "/dev/xvdl", "/dev/xvdm", "/dev/xvdn", "/dev/xvdo", "/dev/xvdp", "/dev/xvdq", "/dev/xvdr", "/dev/xvds", "/dev/xvdt", "/dev/xvdu", "/dev/xvdv", "/dev/xvdw", "/dev/xvdx", "/dev/xvdy", "/dev/xvdz"]
}

variable "kms_key_id" {
  type    = string
  default = null
}

variable "monitoring" {
  description = "Enabled monitoring"
  type        = bool
  default     = null
}

variable "metadata_http_endpoint_enabled" {
  type    = bool
  default = true
}

variable "metadata_tags_enabled" {
  type    = bool
  default = false
}

variable "metadata_http_put_response_hop_limit" {
  type    = number
  default = 2
}

variable "metadata_http_tokens_required" {
  type    = bool
  default = true
}

variable "enable_volume_tags" {
  type    = bool
  default = true
}

variable "common_tags" {
  type    = map(string)
  default = {}
}

variable "private_tags" {
  type    = any
  default = [{}]
}

variable "delete_on_termination" {
  type    = bool
  default = true
}

variable "encrypted_device" {
  type    = bool
  default = true
}
