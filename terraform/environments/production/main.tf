terraform {
  required_version = ">= 1.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "~> 2.23"
    }
    helm = {
      source  = "hashicorp/helm"
      version = "~> 2.11"
    }
    kubectl = {
      source  = "gavinbunney/kubectl"
      version = "~> 1.14"
    }
  }

  backend "s3" {
    key = "environments/production/terraform.tfstate"
  }
}

provider "aws" {
  region = var.aws_region
}

locals {
  environment = "production"
  vpc_cidr    = "10.0.0.0/16"
  azs         = ["${var.aws_region}a", "${var.aws_region}b", "${var.aws_region}c"]

  tags = {
    Environment = local.environment
    Terraform   = "true"
    Project     = "EKS-Lab"
  }
}
