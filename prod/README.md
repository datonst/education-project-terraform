# Production Infrastructure

This directory contains the production infrastructure configuration using Terraform.

## Environment Variables vs Secrets

The backend application uses both environment variables and secrets stored in AWS SSM Parameter Store:

### Environment Variables (Non-sensitive)
- `PORT`: Application port (3000)
- `AWS_REGION`: AWS region
- `AWS_BUCKET`: S3 bucket name for frontend
- `CLOUDFRONT_DOMAIN`: CloudFront domain name

### Secrets (Sensitive - stored in SSM Parameter Store)
- `AWS_ACCESS_KEY_ID`: AWS access key for backend services
- `AWS_SECRET_ACCESS_KEY`: AWS secret access key
- `COGNITO_USER_POOL_ID`: Cognito user pool ID
- `COGNITO_APP_CLIENT_ID`: Cognito app client ID
- `MONGODB_URI`: Complete MongoDB connection string

## Setup

1. **Copy terraform.tfvars.example to terraform.tfvars:**
   ```bash
   cp terraform.tfvars.example terraform.tfvars
   ```

2. **Edit terraform.tfvars with your values:**
   ```hcl
   aws_access_key_id     = "your-actual-access-key"
   aws_secret_access_key = "your-actual-secret-key"
   ```

3. **Initialize and deploy:**
   ```bash
   terraform init
   terraform plan
   terraform apply
   ```

## Security Benefits

- **Encrypted storage**: Sensitive values are encrypted using AWS KMS
- **Access control**: Only ECS tasks can access the parameters
- **Audit trail**: Parameter access is logged in CloudTrail
- **No exposure in logs**: Secrets don't appear in application logs

## Parameter Naming Convention

Parameters follow the pattern: `/{prefix}/backend/{parameter_name}`

Example: `/team4uet/backend/aws_access_key_id`

## Monitoring

- CloudWatch logs: `/ecs/{service-name}`
- Parameter access can be monitored via CloudTrail 