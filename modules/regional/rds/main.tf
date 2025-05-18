resource "aws_db_instance" "db" {
  identifier = var.identifier

  engine            = var.engine
  engine_version    = var.engine_version
  instance_class    = var.instance_class
  allocated_storage = var.allocated_storage
  storage_type      = var.storage_type
  storage_encrypted = var.storage_encrypted
  kms_key_id        = var.kms_key_id
  license_model     = var.license_model

  db_name                             = var.db_name
  username                            = var.username
  password                            = var.password
  port                                = var.port
  iam_database_authentication_enabled = var.iam_database_authentication_enabled
  custom_iam_instance_profile         = var.custom_iam_instance_profile

  vpc_security_group_ids = var.vpc_security_group_ids
  db_subnet_group_name   = var.db_subnet_group_name
  parameter_group_name   = var.parameter_group_name
  option_group_name      = var.option_group_name
  network_type           = var.network_type

  availability_zone  = var.availability_zone
  multi_az           = var.multi_az
  iops               = var.iops
  storage_throughput = var.storage_throughput
  ca_cert_identifier = var.ca_cert_identifier

  allow_major_version_upgrade = var.allow_major_version_upgrade
  auto_minor_version_upgrade  = var.auto_minor_version_upgrade
  apply_immediately           = var.apply_immediately
  maintenance_window          = var.maintenance_window

  replicate_source_db                   = var.replicate_source_db
  replica_mode                          = var.replica_mode
  backup_retention_period               = var.backup_retention_period
  enabled_cloudwatch_logs_exports       = var.enabled_cloudwatch_logs_exports
  performance_insights_kms_key_id       = var.performance_insights_kms_key_id
  performance_insights_retention_period = var.performance_insights_retention_period
  performance_insights_enabled          = var.performance_insights_enabled

  skip_final_snapshot   = var.skip_final_snapshot
  copy_tags_to_snapshot = var.copy_tags_to_snapshot

  deletion_protection = var.deletion_protection

  tags = var.tags
  lifecycle {
    create_before_destroy = true
  }
}
