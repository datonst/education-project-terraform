terraform {
  backend "s3" {
    bucket = "team4uet-prod-infra-backend"
    key    = "prod/aws-github-actions-oidc.tfstate"
    region = "ap-southeast-1"
  }
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "5.98.0"
    }
  }

  required_version = ">= 1.2.0"
}
