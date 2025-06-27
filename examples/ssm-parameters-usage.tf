# Example: Using SSM Parameters with ECS Service

# Create SSM parameters
module "app_ssm_parameters" {
  source = "../modules/regional/ssm-parameters"

  parameters = {
    "/myapp/prod/database/host" = {
      type        = "String"
      value       = "db.example.com"
      description = "Database host for production"
    }
    "/myapp/prod/database/port" = {
      type        = "String"
      value       = "5432"
      description = "Database port"
    }
    "/myapp/prod/database/username" = {
      type        = "SecureString"
      value       = "myapp_user"
      description = "Database username"
    }
    "/myapp/prod/database/password" = {
      type        = "SecureString"
      value       = "secure_password"
      description = "Database password"
    }
    "/myapp/prod/api/key" = {
      type        = "SecureString"
      value       = "api_secret_key"
      description = "External API key"
    }
  }

  tags = {
    Environment = "production"
    Application = "myapp"
    ManagedBy   = "terraform"
  }
}

# Use parameters in ECS service
module "app_ecs_service" {
  source = "../modules/regional/ecs_service"

  service_name       = "myapp-service"
  ecs_cluster_id     = "arn:aws:ecs:region:account:cluster/my-cluster"
  ecr_repository_url = "123456789012.dkr.ecr.region.amazonaws.com/myapp"
  image_tag          = "latest"
  container_name     = "myapp"

  task_cpu         = 512
  task_memory      = 1024
  container_cpu    = 256
  container_memory = 512
  container_port   = 3000

  desired_count      = 2
  subnet_ids         = ["subnet-12345", "subnet-67890"]
  security_group_ids = ["sg-abcdef"]
  assign_public_ip   = false

  # Non-sensitive environment variables
  environment_variables = [
    {
      name  = "NODE_ENV"
      value = "production"
    },
    {
      name  = "LOG_LEVEL"
      value = "info"
    }
  ]

  # Sensitive data from SSM Parameter Store
  secrets = [
    {
      name      = "DB_HOST"
      valueFrom = module.app_ssm_parameters.parameter_arns["/myapp/prod/database/host"]
    },
    {
      name      = "DB_PORT"
      valueFrom = module.app_ssm_parameters.parameter_arns["/myapp/prod/database/port"]
    },
    {
      name      = "DB_USERNAME"
      valueFrom = module.app_ssm_parameters.parameter_arns["/myapp/prod/database/username"]
    },
    {
      name      = "DB_PASSWORD"
      valueFrom = module.app_ssm_parameters.parameter_arns["/myapp/prod/database/password"]
    },
    {
      name      = "API_KEY"
      valueFrom = module.app_ssm_parameters.parameter_arns["/myapp/prod/api/key"]
    }
  ]

  region = "us-west-2"
  tags = {
    Environment = "production"
    Application = "myapp"
  }

  depends_on = [module.app_ssm_parameters]
}

# Output parameter ARNs for reference
output "parameter_arns" {
  description = "ARNs of created SSM parameters"
  value       = module.app_ssm_parameters.parameter_arns
}

output "ecs_service_arn" {
  description = "ARN of the ECS service"
  value       = module.app_ecs_service.service_id
}
