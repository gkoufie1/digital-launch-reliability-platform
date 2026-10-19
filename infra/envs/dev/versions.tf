terraform {
  required_version = ">= 1.10"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.69"
    }
  }

  # Bucket is supplied at init time: terraform init -backend-config=backend.hcl
  backend "s3" {
    key          = "dev/terraform.tfstate"
    region       = "us-east-1"
    encrypt      = true
    use_lockfile = true
  }
}

provider "aws" {
  region = var.aws_region

  default_tags {
    tags = {
      Project     = "digital-launch-reliability-platform"
      Environment = var.environment
      ManagedBy   = "terraform"
      Repository  = "github.com/gkoufie1/digital-launch-reliability-platform"
    }
  }
}
