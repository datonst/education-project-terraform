# DocumentDB Cluster outputs
output "cluster_id" {
  description = "The DocumentDB cluster identifier"
  value       = aws_docdb_cluster.default.id
}

output "cluster_arn" {
  description = "Amazon Resource Name (ARN) of cluster"
  value       = aws_docdb_cluster.default.arn
}

output "cluster_endpoint" {
  description = "The DocumentDB cluster endpoint"
  value       = aws_docdb_cluster.default.endpoint
}

output "cluster_reader_endpoint" {
  description = "The DocumentDB cluster reader endpoint"
  value       = aws_docdb_cluster.default.reader_endpoint
}

output "cluster_port" {
  description = "The DocumentDB cluster port"
  value       = aws_docdb_cluster.default.port
}

output "cluster_master_username" {
  description = "The DocumentDB cluster master username"
  value       = aws_docdb_cluster.default.master_username
}

output "cluster_master_password" {
  description = "The DocumentDB cluster master password"
  value       = aws_docdb_cluster.default.master_password
  sensitive   = true
}

output "cluster_members" {
  description = "List of DocumentDB instances that are a part of this cluster"
  value       = aws_docdb_cluster.default.cluster_members
}

output "cluster_hosted_zone_id" {
  description = "The Route53 Hosted Zone ID of the endpoint"
  value       = aws_docdb_cluster.default.hosted_zone_id
}

# Cluster Instance outputs
output "cluster_instance_ids" {
  description = "List of DocumentDB cluster instance identifiers"
  value       = aws_docdb_cluster_instance.cluster_instances[*].id
}

output "cluster_instance_arns" {
  description = "List of Amazon Resource Names (ARN) of cluster instances"
  value       = aws_docdb_cluster_instance.cluster_instances[*].arn
}

output "cluster_instance_endpoints" {
  description = "List of DocumentDB cluster instance endpoints"
  value       = aws_docdb_cluster_instance.cluster_instances[*].endpoint
}

# Subnet Group outputs
output "subnet_group_id" {
  description = "The DocumentDB subnet group name"
  value       = aws_docdb_subnet_group.default.id
}

output "subnet_group_arn" {
  description = "The ARN of the DocumentDB subnet group"
  value       = aws_docdb_subnet_group.default.arn
}

# Parameter Group outputs
output "parameter_group_id" {
  description = "The DocumentDB cluster parameter group name"
  value       = aws_docdb_cluster_parameter_group.default.id
}

output "parameter_group_arn" {
  description = "The ARN of the DocumentDB cluster parameter group"
  value       = aws_docdb_cluster_parameter_group.default.arn
}
