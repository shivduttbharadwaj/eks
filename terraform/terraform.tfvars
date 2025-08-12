# AWS Region
aws_region = "us-east-1"

# Cluster Configuration
cluster_name    = "production-eks-cluster"
cluster_version = "1.31"

# VPC Configuration
vpc_cidr = "10.0.0.0/16"

# Node Group Configuration
instance_types = ["m5.xlarge"]
min_size      = 2
max_size      = 10
desired_size  = 3

# Environment
environment = "production"

# Grafana Admin Password
grafana_admin_password = "EKSlab2023!"

# Tags
tags = {
  Environment = "production"
  Terraform   = "true"
  Project     = "EKS-Lab"
  Owner       = "DevOps-Team"
}
