module "eks" {
  source  = "terraform-aws-modules/eks/aws"
  version = "~> 19.0"

  cluster_name    = var.cluster_name
  cluster_version = var.cluster_version

  vpc_id     = var.vpc_id
  subnet_ids = var.subnet_ids

  # Enable EKS Managed Node Groups
  eks_managed_node_groups = var.eks_managed_node_groups != {} ? var.eks_managed_node_groups : {
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

      tags = merge(
        var.tags,
        {
          Environment = var.environment
        }
      )
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

  # AWS Auth configuration
  manage_aws_auth_configmap = true
  aws_auth_users           = var.aws_auth_users
  aws_auth_roles          = var.aws_auth_roles

  tags = merge(
    var.tags,
    {
      Environment = var.environment
      Terraform   = "true"
    }
  )
}
