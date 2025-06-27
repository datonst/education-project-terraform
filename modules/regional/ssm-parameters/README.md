# SSM Parameters Module

This module creates AWS Systems Manager (SSM) Parameters for storing configuration and secrets.

## Features

- Creates SSM parameters with different types (String, SecureString)
- Automatic encryption for SecureString parameters
- Support for custom KMS keys
- Tag support

## Usage

```hcl
module "app_parameters" {
  source = "../modules/regional/ssm-parameters"
  
  parameters = {
    "/myapp/database/host" = {
      type        = "String"
      value       = "db.example.com"
      description = "Database host"
    }
    "/myapp/database/password" = {
      type        = "SecureString"
      value       = var.db_password
      description = "Database password"
      key_id      = "alias/myapp-key"  # Optional: custom KMS key
    }
  }
  
  tags = {
    Environment = "production"
    Application = "myapp"
  }
}
```

## Using with ECS

To use these parameters as secrets in ECS containers:

```hcl
module "ecs_service" {
  source = "../modules/regional/ecs_service"
  
  # ... other configuration ...
  
  secrets = [
    {
      name      = "DB_HOST"
      valueFrom = module.app_parameters.parameter_arns["/myapp/database/host"]
    },
    {
      name      = "DB_PASSWORD"
      valueFrom = module.app_parameters.parameter_arns["/myapp/database/password"]
    }
  ]
}
```

## Parameter Types

- **String**: Plain text values
- **SecureString**: Encrypted values using KMS

## Best Practices

1. Use SecureString for sensitive data (passwords, API keys, etc.)
2. Use hierarchical naming convention (e.g., `/app/env/component/setting`)
3. Add meaningful descriptions
4. Use custom KMS keys for production workloads
5. Apply appropriate tags for cost tracking and compliance

## Inputs

| Name       | Description                           | Type          | Default | Required |
| ---------- | ------------------------------------- | ------------- | ------- | :------: |
| parameters | Map of SSM parameters to create       | `map(object)` | `{}`    |    no    |
| tags       | A map of tags to add to all resources | `map(string)` | `{}`    |    no    |

## Outputs

| Name            | Description                         |
| --------------- | ----------------------------------- |
| parameter_arns  | ARNs of the created SSM parameters  |
| parameter_names | Names of the created SSM parameters |