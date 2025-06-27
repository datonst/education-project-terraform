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
    },
    {
      "cidr_blocks" : ["0.0.0.0/0"],
      "from_port" : 4173,
      "to_port" : 4173,
      "protocol" : "tcp"
    },
    {
      "cidr_blocks" : ["0.0.0.0/0"],
      "from_port" : 3000,
      "to_port" : 3000,
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

module "security_group_documentdb" {
  source = "../modules/regional/security-groups"

  sg_name = "documentdb-sg"
  vpc_id  = module.vpc.vpc_id

  ingress_rules = [{
    # "cidr_blocks" : ["10.0.0.0/16"],
    cidr_blocks = ["0.0.0.0/0"],
    "from_port" : 27017,
    "to_port" : 27017,
    "protocol" : "tcp"
    },
    {
      # Cho phép ICMP (ping)
      cidr_blocks = ["0.0.0.0/0"], # HOẶC IP/SG cụ thể của nguồn
      from_port   = -1,            # Hoặc 8 cho Echo Request
      to_port     = -1,            # Hoặc 0 cho Echo Request
      protocol    = "icmp"
    }
  ]

  egress_rules = [{
    # "cidr_blocks" : ["10.0.0.0/16"],
    cidr_blocks = ["0.0.0.0/0"],
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
resource "local_file" "ssh_key" {
  filename = "${aws_key_pair.key_pair.key_name}.pem"
  content  = tls_private_key.key_pair.private_key_pem
}

data "aws_ami" "ubuntu" {
  most_recent = true
  owners      = ["099720109477"]
  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-jammy-22.04-amd64-server-*"]
  }
  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
  filter {
    name   = "architecture"
    values = ["x86_64"]
  }
  filter {
    name   = "root-device-type"
    values = ["ebs"]
  }
}

module "ec2-public" {
  source        = "../modules/regional/ec2/"
  name          = "${local.prefix}-jumphost"
  ami_id        = data.aws_ami.ubuntu.id
  instance_type = ["t2.micro"]
  key_name      = aws_key_pair.key_pair.key_name

  ec2_ips                     = ["10.0.0.10"]
  subnet_id                   = element(module.vpc.vpc_public_subnet_ids, 1)
  vpc_id                      = module.vpc.vpc_id
  associate_public_ip_address = true
  vpc_security_group_ids      = [module.security_group_ec2.security_group_id]

  volume_size = ["30"]
}




# ECR

module "frontend_ecr" {
  source   = "../modules/regional/ecr"
  ecr_name = "${local.prefix}-frontend"
}

module "backend_ecr" {
  source   = "../modules/regional/ecr"
  ecr_name = "${local.prefix}-backend"
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

# module "s3-gateway" {
#   source          = "../modules/regional/s3-gateway"
#   vpc_id          = module.vpc.vpc_id
#   region          = local.region
#   route_table_ids = module.vpc.aws_route_table_association_private
# }

# DocumentDB
module "documentdb" {
  source = "../modules/regional/documentdb"

  cluster_identifier = "${local.prefix}-documentdb"
  master_username    = "myprojectadmin"
  master_password    = "admin123456"

  subnet_ids             = module.vpc.vpc_database_subnet_ids
  subnet_group_name      = "${local.prefix}-documentdb-subnet-group"
  vpc_security_group_ids = [module.security_group_documentdb.security_group_id]

  parameter_group_name = "${local.prefix}-documentdb-params"
  family               = "docdb5.0"

  instance_class = "db.t3.medium"
  instance_count = 1

  backup_retention_period = 7
  preferred_backup_window = "07:00-09:00"
  skip_final_snapshot     = true
  deletion_protection     = false

  storage_encrypted = true
  port              = 27017

  enabled_cloudwatch_logs_exports = ["audit", "profiler"]

  cluster_parameters = [
    {
      name  = "audit_logs"
      value = "enabled"
    },
    {
      name  = "profiler"
      value = "enabled"
    }
  ]

  tags = merge(local.tags, {
    Name = "${local.prefix}-documentdb"
  })
}

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
# module "waf_cloudfront" {
#   providers = {
#     aws = aws.us
#   }
#   source    = "../modules/regional/waf"
#   waf_names = "${local.prefix}-waf"
#   tags      = local.tags
# }

# Cloudfront
module "cloudfront" {
  source                = "../modules/regional/cloudfront"
  origin_id             = "${local.prefix}-cf"
  regional_domain_name  = module.application-loadbalancer.enpoint_alb
  tags                  = local.tags
  s3_bucket_arn         = module.s3.s3_bucket.arn
  s3_bucket_domain_name = module.s3.s3_bucket.bucket_domain_name
  s3_bucket_id          = module.s3.s3_bucket.bucket
  domain_names          = [local.domain_name]
  acm_certificate_arn   = module.acm_cloudfront.acm_certificate_arn
  # web_acl_id                     = module.waf_cloudfront.web_acl_id
  cloudfront_default_certificate = false
  ssl_support_method             = "sni-only"
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
    # module.waf_cloudfront
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
      "from_port" : 8080,
      "to_port" : 8080,
      "protocol" : "tcp"
    },
    {
      "cidr_blocks" : ["0.0.0.0/0"],
      "from_port" : 3000,
      "to_port" : 3000,
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
module "frontend_docker_image" {
  source             = "../modules/regional/docker_image"
  docker_file_path   = "${path.module}/../app/Dockerfile"
  source_path        = "${path.module}/../app"
  ecr_repository_url = module.frontend_ecr.repository_url
  region             = local.region
  image_tag          = "latest"
}


module "backend_docker_image" {
  source             = "../modules/regional/docker_image"
  docker_file_path   = "${path.module}/../app/Dockerfile"
  source_path        = "${path.module}/../app"
  ecr_repository_url = module.backend_ecr.repository_url
  region             = local.region
  image_tag          = "latest"
}
# Target Group for ALB
resource "aws_lb_target_group" "app" {
  name        = "${local.prefix}-tg"
  port        = 80
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
resource "aws_lb_target_group" "app_backend" {
  name        = "${local.prefix}-tg-backend"
  port        = 3000
  protocol    = "HTTP"
  vpc_id      = module.vpc.vpc_id
  target_type = "ip"

  health_check {
    enabled             = true
    interval            = 30
    path                = "/"
    port                = "traffic-port"
    healthy_threshold   = 3
    unhealthy_threshold = 5
    timeout             = 10
    protocol            = "HTTP"
    matcher             = "200"
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
  depends_on = [aws_lb_target_group.app]
}

# ALB Listener Rule for Backend API
resource "aws_lb_listener_rule" "api" {
  listener_arn = aws_lb_listener.http.arn
  priority     = 100

  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.app_backend.arn
  }

  condition {
    path_pattern {
      values = ["/api/*", "/api-docs/*", "/api", "/api-docs"]
    }
  }
  depends_on = [aws_lb_target_group.app_backend]
}

# ECS Service
module "frontend_ecs_service" {
  source = "../modules/regional/ecs_service"

  service_name       = "${local.prefix}-frontend-service"
  ecs_cluster_id     = module.ecs.cluster_id
  ecr_repository_url = module.frontend_ecr.repository_url
  image_tag          = module.frontend_docker_image.image_tag
  container_name     = "${local.prefix}-frontend"

  task_cpu         = 512
  task_memory      = 1024
  container_cpu    = 256
  container_memory = 512
  container_port   = 80

  desired_count      = 1
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

  depends_on = [module.frontend_docker_image.build_completed]
}

module "backend_ecs_service" {
  source = "../modules/regional/ecs_service"

  service_name       = "${local.prefix}-backend-service"
  ecs_cluster_id     = module.ecs.cluster_id
  ecr_repository_url = module.backend_ecr.repository_url
  image_tag          = module.backend_docker_image.image_tag
  container_name     = "${local.prefix}-backend"

  task_cpu         = 512
  task_memory      = 1024
  container_cpu    = 256
  container_memory = 512
  container_port   = 3000

  desired_count      = 1
  subnet_ids         = module.vpc.vpc_private_subnet_ids
  security_group_ids = [module.security_group_ecs.security_group_id]
  assign_public_ip   = false

  lb_target_group_arn = aws_lb_target_group.app_backend.arn

  # Non-sensitive environment variables
  environment_variables = [
    {
      name  = "PORT"
      value = "3000"
    },
    {
      name  = "AWS_REGION"
      value = local.region
    },
    {
      name  = "AWS_BUCKET"
      value = "team4-storage-backend"
    },
    {
      name  = "CLOUDFRONT_DOMAIN"
      value = local.domain_name
    }
  ]

  # Sensitive data from SSM Parameter Store
  secrets = [
    {
      name      = "AWS_ACCESS_KEY_ID"
      valueFrom = module.backend_ssm_parameters.parameter_arns["/${local.prefix}/backend/aws_access_key_id"]
    },
    {
      name      = "AWS_SECRET_ACCESS_KEY"
      valueFrom = module.backend_ssm_parameters.parameter_arns["/${local.prefix}/backend/aws_secret_access_key"]
    },
    {
      name      = "COGNITO_USER_POOL_ID"
      valueFrom = module.backend_ssm_parameters.parameter_arns["/${local.prefix}/backend/cognito_user_pool_id"]
    },
    {
      name      = "COGNITO_APP_CLIENT_ID"
      valueFrom = module.backend_ssm_parameters.parameter_arns["/${local.prefix}/backend/cognito_app_client_id"]
    },
    {
      name      = "MONGODB_URI"
      valueFrom = module.backend_ssm_parameters.parameter_arns["/${local.prefix}/backend/mongodb_uri"]
    }
  ]

  region = local.region
  tags   = local.tags

  depends_on = [module.backend_docker_image, module.documentdb, module.backend_ssm_parameters, module.cloudfront, module.s3]
}

# SSM Parameters for backend configuration
module "backend_ssm_parameters" {
  source = "../modules/regional/ssm-parameters"

  parameters = {
    # Sensitive parameters (SecureString)
    "/${local.prefix}/backend/aws_access_key_id" = {
      type        = "SecureString"
      value       = var.aws_access_key_id
      description = "AWS Access Key ID for backend"
    }
    "/${local.prefix}/backend/aws_secret_access_key" = {
      type        = "SecureString"
      value       = var.aws_secret_access_key
      description = "AWS Secret Access Key for backend"
    }
    "/${local.prefix}/backend/mongodb_uri" = {
      type        = "SecureString"
      value       = "mongodb://${module.documentdb.cluster_master_username}:${module.documentdb.cluster_master_password}@${module.documentdb.cluster_endpoint}:27017/e-learn?ssl=true&tlsCAFile=global-bundle.pem"
      description = "MongoDB connection URI"
    }
    "/${local.prefix}/backend/cognito_user_pool_id" = {
      type        = "SecureString"
      value       = module.cognito.user_pool_id
      description = "Cognito User Pool ID"
    }
    "/${local.prefix}/backend/cognito_app_client_id" = {
      type        = "SecureString"
      value       = module.cognito.app_client_id
      description = "Cognito App Client ID"
    }
  }

  tags = local.tags

  depends_on = [module.documentdb, module.cognito]
}

# Cognito User Pool để xác thực người dùng
module "cognito" {
  source        = "../modules/regional/cognito"
  prefix        = local.prefix
  domain_prefix = "${local.prefix}-auth"
  callback_urls = ["https://d84l1y8p4kdic.cloudfront.net"]
  tags          = local.tags
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
output "documentdb_cluster_endpoint" {
  description = "DocumentDB cluster endpoint"
  value       = module.documentdb.cluster_endpoint
}

output "documentdb_cluster_reader_endpoint" {
  description = "DocumentDB cluster reader endpoint"
  value       = module.documentdb.cluster_reader_endpoint
}

output "documentdb_cluster_port" {
  description = "DocumentDB cluster port"
  value       = module.documentdb.cluster_port
}

output "documentdb_cluster_id" {
  description = "DocumentDB cluster identifier"
  value       = module.documentdb.cluster_id
}

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

