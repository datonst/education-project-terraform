module "vpc" {
  source = "github.com/terraform-aws-modules/terraform-aws-vpc?ref=v5.1.2"

  name = var.vpc_name
  cidr = var.vpc_cidr

  azs              = var.vpc_azs
  private_subnets  = var.vpc_private_subnets
  public_subnets   = var.vpc_public_subnets
  database_subnets = var.vpc_database_subnets

  enable_nat_gateway   = var.vpc_enable_nat_gateway
  single_nat_gateway   = var.vpc_single_nat_gateway
  enable_dns_hostnames = var.vpc_enable_dns_hostnames

  public_subnet_names   = var.public_subnet_names
  private_subnet_names  = var.private_subnet_names
  database_subnet_names = var.database_subnet_names

  public_subnet_tags  = var.vpc_public_subnet_tags
  private_subnet_tags = var.vpc_private_subnet_tags
  tags                = var.vpc_tags
}