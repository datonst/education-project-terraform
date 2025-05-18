# VPC
module "vpc" {
  source                = "../modules/regional/vpc/"
  vpc_name              = "${local.prefix}-vpc"
  vpc_azs               = ["${local.region}a", "${local.region}b"]
  vpc_cidr              = "10.0.0.0/16"
  vpc_public_subnets    = ["10.0.1.0/24", "10.0.0.0/24"]
  vpc_private_subnets   = ["10.0.16.0/20", "10.0.32.0/20"]
  vpc_database_subnets  = ["10.0.64.0/24", "10.0.65.0/24"]
  public_subnet_names   = ["${local.prefix}-pub-apse1-az2", "${local.prefix}-pub-apse1-az1"]
  private_subnet_names  = ["${local.prefix}-app-apse1-az1", " ${local.prefix}-app-apse1-az2"]
  database_subnet_names = ["${local.prefix}-db-apse1-az1", "${local.prefix}-db-apse1-az2"]

  #  vpc_single_nat_gateway   = local.is_non_prod
  vpc_single_nat_gateway   = true
  vpc_enable_nat_gateway   = true
  vpc_enable_dns_hostnames = true
  vpc_tags                 = local.tags
}


# Security Groups
module "security_group_ec2" {
  source  = "../modules/regional/security-groups"
  vpc_id  = module.vpc.vpc_id
  sg_name = "SG-EC2-JumpHost"
  ingress_rules = [{
    "cidr_blocks" : ["0.0.0.0/0"],
    "from_port" : 22,
    "to_port" : 22,
    "protocol" : "tcp"
    }, {
    "cidr_blocks" : ["0.0.0.0/0"],
    "from_port" : 1194,
    "to_port" : 1194,
    "protocol" : "udp"
  }]

  egress_rules = [{
    "cidr_blocks" : ["0.0.0.0/0"],
    "from_port" : 0,
    "to_port" : 0,
    "protocol" : "-1"
  }]
}

module "security_group_rds" {
  source = "../modules/regional/security-groups"

  sg_name = "rds-sg"
  vpc_id  = module.vpc.vpc_id

  ingress_rules = [{
    "cidr_blocks" : ["10.0.0.0/16"],
    "from_port" : 5432,
    "to_port" : 5432,
    "protocol" : "tcp"
  }]

  egress_rules = [{
    "cidr_blocks" : ["10.0.0.0/16"],
    "from_port" : 0,
    "to_port" : 0,
    "protocol" : "-1"
  }]
}


module "security_group_ec2_alb" {
  source = "../modules/regional/security-groups"

  sg_name = "ec2-sg"
  vpc_id  = module.vpc.vpc_id

  ingress_rules = [
    {
      "cidr_blocks" : ["0.0.0.0/0"],
      "from_port" : 80,
      "to_port" : 80,
      "protocol" : "tcp"
    },
    {
      "cidr_blocks" : ["0.0.0.0/0"],
      "from_port" : 443,
      "to_port" : 443,
      "protocol" : "tcp"
    },
    {
      "cidr_blocks" : ["0.0.0.0/0"],
      "from_port" : 4500,
      "to_port" : 4500,
      "protocol" : "tcp"
    }
  ]

  egress_rules = [{
    "cidr_blocks" : ["0.0.0.0/0"],
    "from_port" : 0,
    "to_port" : 0,
    "protocol" : "-1"
  }]
}

# EC2
resource "tls_private_key" "key_pair" {
  algorithm = "RSA"
  rsa_bits  = 4096
}
# Create the Key Pair
resource "aws_key_pair" "key_pair" {
  key_name   = "web-ec2-key-pair"
  public_key = tls_private_key.key_pair.public_key_openssh
}
# Save file
# resource "local_file" "ssh_key" {
#   filename = "key.pem"
#   content  = tls_private_key.key_pair.private_key_pem
# }

module "ec2-public" {
  source        = "../modules/regional/ec2/"
  name          = "${local.prefix}-jumphost"
  ami_id        = "ami-0b4bb4751e9a8fbdb"
  instance_type = ["t3.micro"]
  key_name      = aws_key_pair.key_pair.key_name

  ec2_ips                     = ["10.0.0.10"]
  subnet_id                   = element(module.vpc.vpc_public_subnet_ids, 1)
  vpc_id                      = module.vpc.vpc_id
  associate_public_ip_address = true
  vpc_security_group_ids      = [module.security_group_ec2.security_group_id]

  volume_size = ["30"]
}


resource "aws_service_discovery_http_namespace" "example" {
  name        = local.prefix
  description = "example"
}

# ECR

module "ecr" {
  source   = "../modules/regional/ecr"
  ecr_name = local.prefix
}

# ECS
module "ecs" {
  source  = "terraform-aws-modules/ecs/aws"
  version = "5.12.1"

  cluster_name = "${local.prefix}-ecs"

  cluster_configuration = {
    execute_command_configuration = {
      logging = "OVERRIDE"
      log_configuration = {
        cloud_watch_log_group_name = "/aws/ecs/aws-ec2"
      }
    }
  }

  fargate_capacity_providers = {
    FARGATE = {
      default_capacity_provider_strategy = {
        weight = 50
      }
    }
    FARGATE_SPOT = {
      default_capacity_provider_strategy = {
        weight = 50
      }
    }
  }

  services = {}

  tags = local.tags

}

# S3
module "s3" {
  source = "../modules/regional/s3"
  bucket = "${local.prefix}-frontend"
  tags   = local.tags
}

# module "s3-app" {
#   source = "../modules/regional/s3"
#   bucket = "${local.prefix}-app"
#   tags   = local.tags
# }

module "s3-gateway" {
  source          = "../modules/regional/s3-gateway"
  vpc_id          = module.vpc.vpc_id
  region          = local.region
  route_table_ids = module.vpc.aws_route_table_association_private
}

# RDS Postgres
resource "aws_db_subnet_group" "default" {
  name       = "main"
  subnet_ids = module.vpc.vpc_database_subnet_ids

  tags = {
    Name = "${local.prefix}-subnet-group"
  }
}

module "my_db_postgres" {
  source            = "../modules/regional/rds"
  availability_zone = "${local.region}a"
  identifier        = "${local.prefix}-db"

  engine         = "postgres"
  engine_version = "16.6"
  instance_class = "db.t3.micro"

  allocated_storage = 10
  enabled_cloudwatch_logs_exports = [
    "postgresql", "upgrade"
  ]
  db_name  = "myprojectadmin"
  username = "myprojectadmin"
  password = "admin123456"
  port     = 5432

  multi_az                   = false
  db_subnet_group_name       = aws_db_subnet_group.default.name
  vpc_security_group_ids     = [module.security_group_rds.security_group_id]
  backup_retention_period    = 7
  skip_final_snapshot        = true
  deletion_protection        = false
  auto_minor_version_upgrade = false
  tags = {
    Name = "${local.prefix}-db"
  }
}

# module "my_db_postgres_replica" {
#   source = "../modules/regional/rds"

#   identifier        = "${local.prefix}-replica"
#   availability_zone = "${local.region}b"

#   replicate_source_db = module.my_db_postgres.db_instance_identifier

#   engine                  = "postgres"
#   engine_version          = "14"
#   instance_class          = "db.m5.large"
#   backup_retention_period = 0
#   allocated_storage       = 10

#   enabled_cloudwatch_logs_exports = [
#     "postgresql", "upgrade"
#   ]
#   port = 5432

#   multi_az               = false
#   vpc_security_group_ids = [module.security_group_rds.security_group_id]

#   skip_final_snapshot = true
#   deletion_protection = false

#   tags = {
#     Name = "${local.prefix}-replica"
#   }
# }

# ALB

module "application-loadbalancer" {
  source     = "../modules/regional/loadbalancer"
  lb_name    = "${local.prefix}-alb"
  subnet_ids = module.vpc.vpc_public_subnet_ids
  common_tags = {
    Name = "name"
  }
  internal           = false
  load_balancer_type = "application"
  security_group_ids = [module.security_group_ec2_alb.security_group_id]
}

# WAF
module "waf_cloudfront" {
  providers = {
    aws = aws.us
  }
  source    = "../modules/regional/waf"
  waf_names = "${local.prefix}-waf"
  tags      = local.tags
}

# Cloudfront
module "cloudfront" {
  source                = "../modules/regional/cloudfront"
  origin_id             = "${local.prefix}-cf"
  regional_domain_name  = module.application-loadbalancer.enpoint_alb
  tags                  = local.tags
  s3_bucket_arn         = module.s3.s3_bucket.arn
  s3_bucket_domain_name = module.s3.s3_bucket.bucket_domain_name
  s3_bucket_id          = module.s3.s3_bucket.bucket

  acm_certificate_arn            = module.acm_cloudfront.acm_certificate_arn
  web_acl_id                     = module.waf_cloudfront.web_acl_id
  cloudfront_default_certificate = false
  ssl_support_method             = "sni-only"
  domain_names                   = [local.domain_name]
  custom_error_response = [
    {
      error_caching_min_ttl = 10
      error_code            = 403
      response_code         = 200
      response_page_path    = "/index.html"
    },
    {
      error_caching_min_ttl = 10
      error_code            = 404
      response_code         = 200
      response_page_path    = "/index.html"
    }
  ]
  auth_lambda_arn = module.lambda_auth.auth_lambda_arn


  depends_on = [
    module.s3,
    module.waf_cloudfront
  ]
}




# ACM
module "acm_cloudfront" {
  providers = {
    aws = aws.us
  }
  source      = "../modules/regional/acm"
  domain_name = local.domain_name
  tags        = local.tags
}

# module "acm_alb" {
#   source      = "../modules/regional/acm"
#   domain_name = local.domain_name
#   tags        = local.tags
# }

# ECR Repository for my-app
module "my_app_ecr" {
  source   = "../modules/regional/ecr"
  ecr_name = "${local.prefix}-my-app"
}

# Security Group for ECS
module "security_group_ecs" {
  source = "../modules/regional/security-groups"

  sg_name = "${local.prefix}-ecs-sg"
  vpc_id  = module.vpc.vpc_id

  ingress_rules = [
    {
      "cidr_blocks" : ["0.0.0.0/0"],
      "from_port" : 80,
      "to_port" : 80,
      "protocol" : "tcp"
    },
    {
      "cidr_blocks" : ["0.0.0.0/0"],
      "from_port" : 443,
      "to_port" : 443,
      "protocol" : "tcp"
    },
    {
      "cidr_blocks" : ["0.0.0.0/0"],
      "from_port" : 5000,
      "to_port" : 5000,
      "protocol" : "tcp"
    }
  ]

  egress_rules = [{
    "cidr_blocks" : ["0.0.0.0/0"],
    "from_port" : 0,
    "to_port" : 0,
    "protocol" : "-1"
  }]
}

# Build and push Docker image
module "docker_image" {
  source             = "../modules/regional/docker_image"
  docker_file_path   = "/home/datonst/my-project/azure-project/lab2/my-app/Dockerfile"
  source_path        = "/home/datonst/my-project/azure-project/lab2/my-app"
  ecr_repository_url = module.my_app_ecr.repository_url
  region             = local.region
  image_tag          = var.image_tag
  domain_name        = local.domain_name
}

# Target Group for ALB
resource "aws_lb_target_group" "app" {
  name        = "${local.prefix}-tg"
  port        = 5000
  protocol    = "HTTP"
  vpc_id      = module.vpc.vpc_id
  target_type = "ip"

  health_check {
    enabled             = true
    interval            = 30
    path                = "/"
    port                = "traffic-port"
    healthy_threshold   = 3
    unhealthy_threshold = 3
    timeout             = 5
    protocol            = "HTTP"
  }
}

# ALB Listener
resource "aws_lb_listener" "http" {
  load_balancer_arn = module.application-loadbalancer.lb_arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.app.arn
  }
}

# ECS Service
module "ecs_service" {
  source = "../modules/regional/ecs_service"

  service_name       = "${local.prefix}-app-service"
  ecs_cluster_id     = module.ecs.cluster_id
  ecr_repository_url = module.my_app_ecr.repository_url
  image_tag          = module.docker_image.image_tag
  container_name     = "${local.prefix}-app"

  task_cpu         = 512
  task_memory      = 1024
  container_cpu    = 256
  container_memory = 512
  container_port   = 5000

  desired_count      = 2
  subnet_ids         = module.vpc.vpc_private_subnet_ids
  security_group_ids = [module.security_group_ecs.security_group_id]
  assign_public_ip   = false

  lb_target_group_arn = aws_lb_target_group.app.arn

  environment_variables = [
    {
      name  = "ENVIRONMENT"
      value = "production"
    }
  ]

  region = local.region
  tags   = local.tags

  depends_on = [module.docker_image.build_completed]
}



# Cognito User Pool để xác thực người dùng
module "cognito" {
  providers = {
    aws = aws.us
  }
  source        = "../modules/regional/cognito"
  prefix        = local.prefix
  domain_prefix = "${local.prefix}-auth"
  # callback_urls = ["https://${local.domain_name}/login/callback", "https://${local.domain_name}/login/oauth2/callback"]
  # callback_urls = ["https://${local.domain_name}"]
  # logout_urls = ["https://${local.domain_name}/logout"]
  # logout_urls = ["https://${local.domain_name}"]
  tags = local.tags
}

# # Lambda@Edge functions để xác thực request
module "lambda_auth" {
  providers = {
    aws = aws.us
  }
  source                = "../modules/regional/lambda_auth"
  prefix                = local.prefix
  cognito_user_pool_arn = module.cognito.user_pool_arn
  cognito_jwks_uri      = module.cognito.jwks_uri
  s3_bucket_arn         = module.s3.s3_bucket.arn
  tags                  = local.tags
}

# CloudFront để phân phối nội dung


# Outputs 
# output "cloudfront_domain_name" {
#   description = "CloudFront domain name"
#   value       = module.cloudfront.cloudfront_distribution_domain_name
# }

# output "cognito_hosted_ui" {
#   description = "Cognito Hosted UI URL"
#   value       = module.cognito.hosted_ui_url
# }

# output "app_client_id" {
#   description = "Cognito App Client ID"
#   value       = module.cognito.app_client_id
# }

