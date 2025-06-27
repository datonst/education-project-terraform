# Basic cluster configuration
variable "cluster_identifier" {
  description = "The cluster identifier"
  type        = string
}

variable "master_username" {
  description = "Username for the master DB user"
  type        = string
}

variable "master_password" {
  description = "Password for the master DB user"
  type        = string
  sensitive   = true
}

# Networking
variable "subnet_ids" {
  description = "A list of VPC subnet IDs"
  type        = list(string)
}

variable "vpc_security_group_ids" {
  description = "List of VPC security groups to associate"
  type        = list(string)
  default     = []
}

variable "subnet_group_name" {
  description = "Name of the DocumentDB subnet group"
  type        = string
}

# Instance configuration
variable "instance_class" {
  description = "The instance class to use"
  type        = string
  default     = "db.t3.medium"
}

variable "instance_count" {
  description = "Number of instances in the cluster"
  type        = number
  default     = 1
}

# Parameter Group
variable "family" {
  description = "The DocumentDB family"
  type        = string
  default     = "docdb4.0"
}

variable "parameter_group_name" {
  description = "The name of the DocumentDB parameter group"
  type        = string
}

variable "cluster_parameters" {
  description = "A list of DocumentDB parameters to apply"
  type = list(object({
    name  = string
    value = string
  }))
  default = []
}

# Backup and maintenance
variable "backup_retention_period" {
  description = "The days to retain backups for"
  type        = number
  default     = 7
}

variable "preferred_backup_window" {
  description = "The daily time range during which automated backups are created"
  type        = string
  default     = "07:00-09:00"
}

variable "preferred_maintenance_window" {
  description = "The weekly time range during which system maintenance can occur"
  type        = string
  default     = "sun:05:00-sun:06:00"
}

# Security and encryption
variable "storage_encrypted" {
  description = "Specifies whether the DocumentDB cluster is encrypted"
  type        = bool
  default     = true
}

variable "kms_key_id" {
  description = "The ARN for the KMS encryption key"
  type        = string
  default     = null
}

variable "deletion_protection" {
  description = "A value that indicates whether the DocumentDB cluster has deletion protection enabled"
  type        = bool
  default     = false
}

variable "skip_final_snapshot" {
  description = "Determines whether a final DocumentDB snapshot is created before the DocumentDB cluster is deleted"
  type        = bool
  default     = true
}

# Monitoring and logging
variable "enabled_cloudwatch_logs_exports" {
  description = "List of log types to export to cloudwatch"
  type        = list(string)
  default     = ["audit", "profiler"]
}

# Connection
variable "port" {
  description = "The port on which the DocumentDB accepts connections"
  type        = number
  default     = 27017
}

# Maintenance
variable "auto_minor_version_upgrade" {
  description = "Indicates that minor engine upgrades will be applied automatically to the DocumentDB instance during the maintenance window"
  type        = bool
  default     = true
}

variable "ca_cert_identifier" {
  description = "The identifier of the CA certificate for the DocumentDB instance"
  type        = string
  default     = null
}

# Tags
variable "tags" {
  description = "A map of tags to assign to the resource"
  type        = map(string)
  default     = {}
}


variable "tls" {
  description = "Specifies whether the DocumentDB cluster is encrypted"
  type        = string
  default     = "enabled"
}
