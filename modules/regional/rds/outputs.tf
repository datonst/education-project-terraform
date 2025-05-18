output "db_instance_identifier" {
  description = "The RDS instance identifier"
  value       = try(aws_db_instance.db.identifier, null)
}

output "db_endpoint" {
  value = aws_db_instance.db.endpoint
}
