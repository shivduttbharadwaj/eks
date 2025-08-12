variable "cluster_name" {
  description = "Name of the EKS cluster"
  type        = string
}

variable "cluster_version" {
  description = "Kubernetes version"
  type        = string
}

variable "vpc_id" {
  description = "VPC ID where the EKS cluster will be created"
  type        = string
}

variable "subnet_ids" {
  description = "List of subnet IDs for the EKS cluster"
  type        = list(string)
}

variable "instance_types" {
  description = "List of instance types for the EKS node groups"
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
}

variable "eks_managed_node_groups" {
  description = "Map of EKS managed node group definitions"
  type        = any
  default     = {}
}

variable "aws_auth_users" {
  description = "List of user maps to add to the aws-auth configmap"
  type = list(object({
    userarn  = string
    username = string
    groups   = list(string)
  }))
  default = []
}

variable "aws_auth_roles" {
  description = "List of role maps to add to the aws-auth configmap"
  type = list(object({
    rolearn  = string
    username = string
    groups   = list(string)
  }))
  default = []
}

variable "tags" {
  description = "A map of tags to add to all resources"
  type        = map(string)
  default     = {}
}