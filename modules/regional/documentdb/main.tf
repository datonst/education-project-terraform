# DocumentDB Subnet Group
resource "aws_docdb_subnet_group" "default" {
  name       = var.subnet_group_name
  subnet_ids = var.subnet_ids

  tags = merge(
    var.tags,
    {
      Name = var.subnet_group_name
    }
  )
}

# DocumentDB Cluster Parameter Group
resource "aws_docdb_cluster_parameter_group" "default" {
  family      = var.family
  name        = var.parameter_group_name
  description = "DocumentDB cluster parameter group for ${var.cluster_identifier}"
  parameter {
    name  = "tls"
    value = var.tls
  }
  dynamic "parameter" {
    for_each = var.cluster_parameters
    content {
      name  = parameter.value.name
      value = parameter.value.value
    }
  }

  tags = var.tags
}

# DocumentDB Cluster
resource "aws_docdb_cluster" "default" {
  cluster_identifier      = var.cluster_identifier
  engine                  = "docdb"
  master_username         = var.master_username
  master_password         = var.master_password
  backup_retention_period = var.backup_retention_period
  preferred_backup_window = var.preferred_backup_window
  skip_final_snapshot     = var.skip_final_snapshot
  deletion_protection     = var.deletion_protection

  db_subnet_group_name            = aws_docdb_subnet_group.default.name
  db_cluster_parameter_group_name = aws_docdb_cluster_parameter_group.default.name
  vpc_security_group_ids          = var.vpc_security_group_ids

  storage_encrypted               = var.storage_encrypted
  kms_key_id                      = var.kms_key_id
  port                            = var.port
  preferred_maintenance_window    = var.preferred_maintenance_window
  enabled_cloudwatch_logs_exports = var.enabled_cloudwatch_logs_exports

  tags = merge(
    var.tags,
    {
      Name = var.cluster_identifier
    }
  )
}

# DocumentDB Cluster Instances
resource "aws_docdb_cluster_instance" "cluster_instances" {
  count                        = var.instance_count
  identifier                   = "${var.cluster_identifier}-${count.index}"
  cluster_identifier           = aws_docdb_cluster.default.id
  instance_class               = var.instance_class
  auto_minor_version_upgrade   = var.auto_minor_version_upgrade
  preferred_maintenance_window = var.preferred_maintenance_window
  ca_cert_identifier           = var.ca_cert_identifier

  tags = merge(
    var.tags,
    {
      Name = "${var.cluster_identifier}-${count.index}"
    }
  )
}
