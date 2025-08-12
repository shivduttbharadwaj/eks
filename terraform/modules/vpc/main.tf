module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "~> 5.0"

  name = var.vpc_name
  cidr = var.vpc_cidr

  azs = var.azs
  private_subnets  = var.private_subnets
  public_subnets   = var.public_subnets
  database_subnets = var.database_subnets

  enable_nat_gateway     = true
  single_nat_gateway     = false
  one_nat_gateway_per_az = true

  enable_dns_hostnames = true
  enable_dns_support   = true

  # EKS specific tags
  public_subnet_tags = {
    "kubernetes.io/role/elb"                       = "1"
    "kubernetes.io/cluster/${var.cluster_name}"    = "shared"
    "Environment"                                  = var.environment
  }

  private_subnet_tags = {
    "kubernetes.io/role/internal-elb"              = "1"
    "kubernetes.io/cluster/${var.cluster_name}"    = "shared"
    "Environment"                                  = var.environment
  }

  database_subnet_tags = {
    "Environment" = var.environment
  }

  tags = merge(
    var.tags,
    {
      Environment = var.environment
      Terraform   = "true"
    }
  )
}
