# VPC
module "vpc" {
  source = "../../modules/vpc"

  vpc_name = "${var.cluster_name}-vpc"
  vpc_cidr = local.vpc_cidr
  azs      = local.azs

  private_subnets  = [for i in range(3) : cidrsubnet(local.vpc_cidr, 8, i + 10)]
  public_subnets   = [for i in range(3) : cidrsubnet(local.vpc_cidr, 8, i)]
  database_subnets = [for i in range(3) : cidrsubnet(local.vpc_cidr, 8, i + 20)]

  cluster_name = var.cluster_name
  environment  = local.environment
  tags         = local.tags
}

# EKS
module "eks" {
  source = "../../modules/eks"

  cluster_name    = var.cluster_name
  cluster_version = var.cluster_version

  vpc_id     = module.vpc.vpc_id
  subnet_ids = module.vpc.private_subnets

  instance_types = ["m5.xlarge"]
  min_size      = 2
  max_size      = 10
  desired_size  = 3

  environment = local.environment

  aws_auth_users = [
    {
      userarn  = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:user/admin"
      username = "admin"
      groups   = ["system:masters"]
    }
  ]

  aws_auth_roles = [
    {
      rolearn  = module.eks.cluster_iam_role_arn
      username = "system:node:{{EC2PrivateDNSName}}"
      groups   = ["system:bootstrappers", "system:nodes"]
    }
  ]

  tags = local.tags
}

# Addons
module "addons" {
  source = "../../modules/addons"

  cluster_name                     = module.eks.cluster_id
  cluster_endpoint                = module.eks.cluster_endpoint
  cluster_certificate_authority_data = module.eks.cluster_certificate_authority_data
  oidc_provider_arn               = module.eks.oidc_provider_arn
  aws_region                      = var.aws_region
  vpc_id                          = module.vpc.vpc_id
  environment                     = local.environment

  enable_cluster_autoscaler         = true
  enable_metrics_server             = true
  enable_prometheus                 = true
  enable_aws_load_balancer_controller = true
  enable_aws_cloudwatch_metrics     = true
  enable_fluent_bit                 = true

  grafana_admin_password = var.grafana_admin_password
}

data "aws_caller_identity" "current" {}
