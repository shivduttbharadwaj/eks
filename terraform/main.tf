provider "aws" {
  region = var.aws_region
}

locals {
  cluster_name = var.cluster_name
  tags = {
    Environment = var.environment
    Terraform   = "true"
  }
}

# VPC Module
module "vpc" {
  source = "terraform-aws-modules/vpc/aws"
  version = "~> 5.0"

  name = "${local.cluster_name}-vpc"
  cidr = var.vpc_cidr

  azs             = ["${var.aws_region}a", "${var.aws_region}b", "${var.aws_region}c"]
  private_subnets = [for i in range(3) : cidrsubnet(var.vpc_cidr, 8, i + 10)]
  public_subnets  = [for i in range(3) : cidrsubnet(var.vpc_cidr, 8, i)]
  database_subnets = [for i in range(3) : cidrsubnet(var.vpc_cidr, 8, i + 20)]

  enable_nat_gateway = true
  single_nat_gateway = false
  one_nat_gateway_per_az = true

  enable_dns_hostnames = true
  enable_dns_support   = true

  # EKS specific tags
  public_subnet_tags = {
    "kubernetes.io/role/elb" = "1"
    "kubernetes.io/cluster/${local.cluster_name}" = "shared"
  }
  private_subnet_tags = {
    "kubernetes.io/role/internal-elb" = "1"
    "kubernetes.io/cluster/${local.cluster_name}" = "shared"
  }

  tags = local.tags
}

# EKS Cluster
module "eks" {
  source = "terraform-aws-modules/eks/aws"
  version = "~> 19.0"

  cluster_name    = local.cluster_name
  cluster_version = var.cluster_version

  vpc_id     = module.vpc.vpc_id
  subnet_ids = module.vpc.private_subnets

  # Enable EKS Managed Node Groups
  eks_managed_node_groups = {
    default = {
      min_size     = var.min_size
      max_size     = var.max_size
      desired_size = var.desired_size

      instance_types = var.instance_types
      capacity_type  = "ON_DEMAND"

      disk_size = 100

      labels = {
        Environment = var.environment
      }

      tags = local.tags
    }
  }

  # Enable OIDC provider
  enable_irsa = true

  # Cluster addons
  cluster_addons = {
    coredns = {
      most_recent = true
    }
    kube-proxy = {
      most_recent = true
    }
    vpc-cni = {
      most_recent = true
    }
    aws-ebs-csi-driver = {
      most_recent = true
    }
  }

  # Enable control plane logging
  cluster_enabled_log_types = ["api", "audit", "authenticator", "controllerManager", "scheduler"]

  tags = local.tags
}

# EKS Node Security Group Rules
resource "aws_security_group_rule" "node_ingress_self" {
  description              = "Allow node to communicate with each other"
  from_port               = 0
  protocol                = "-1"
  security_group_id       = module.eks.node_security_group_id
  source_security_group_id = module.eks.node_security_group_id
  to_port                 = 65535
  type                    = "ingress"
}
