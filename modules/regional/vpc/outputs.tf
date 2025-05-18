output "vpc_id" {
  value = module.vpc.vpc_id
}

output "vpc_public_subnet_ids" {
  value = module.vpc.public_subnets
}

output "vpc_private_subnet_ids" {
  value = module.vpc.private_subnets
}

output "vpc_database_subnet_ids" {
  value = module.vpc.database_subnets
}

output "aws_route_table_association_private" {
  value = module.vpc.private_route_table_ids
}
