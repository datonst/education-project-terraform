terraform {
  backend "s3" {
    bucket = "education-t-test-infra-backend"
    key    = "prod/aws-github-actions-oidc.tfstate"
    region = "ap-southeast-1"
  }
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "6.0.0"
    }
  }

  required_version = ">= 1.2.0"
}
