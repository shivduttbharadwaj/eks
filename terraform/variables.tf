variable "aws_region" {
  description = "AWS region"
  type        = string
  default     = "us-east-1"
}

variable "cluster_name" {
  description = "Name of the EKS cluster"
  type        = string
  default     = "production-eks-cluster"
}

variable "cluster_version" {
  description = "Kubernetes version"
  type        = string
  default     = "1.31"
}

variable "vpc_cidr" {
  description = "CIDR block for VPC"
  type        = string
  default     = "10.0.0.0/16"
}

variable "instance_types" {
  description = "Instance types for worker nodes"
  type        = list(string)
  default     = ["m5.xlarge"]
}

variable "min_size" {
  description = "Minimum size of worker node group"
  type        = number
  default     = 2
}

variable "max_size" {
  description = "Maximum size of worker node group"
  type        = number
  default     = 10
}

variable "desired_size" {
  description = "Desired size of worker node group"
  type        = number
  default     = 3
}

variable "environment" {
  description = "Environment name"
  type        = string
  default     = "production"
}

variable "grafana_admin_password" {
  description = "Admin password for Grafana"
  type        = string
  sensitive   = true
  default     = "EKSlab2023!"
}

# Tags
variable "tags" {
  description = "A map of tags to add to all resources"
  type        = map(string)
  default     = {
    Environment = "production"
    Terraform   = "true"
    Project     = "EKS-Lab"
  }
}
