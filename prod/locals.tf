locals {
  region = "ap-southeast-1"
  tags = {
    Environment = "prod"
    Terraform   = "true"
  }
  prefix      = "demo-project-test"
  domain_name = "secureguard.today"
  zone_id     = ""
}

provider "aws" {
  region = "us-east-1"
  alias  = "us"
}

provider "aws" {
  region = "ap-southeast-1"
}


