variable "vpc_name" {
  description = "Name of the VPC"
  type        = string
}

variable "vpc_cidr" {
  description = "CIDR block for VPC"
  type        = string
}

variable "azs" {
  description = "Availability zones for VPC"
  type        = list(string)
}

variable "private_subnets" {
  description = "Private subnet CIDR ranges"
  type        = list(string)
}

variable "public_subnets" {
  description = "Public subnet CIDR ranges"
  type        = list(string)
}

variable "database_subnets" {
  description = "Database subnet CIDR ranges"
  type        = list(string)
}

variable "cluster_name" {
  description = "EKS cluster name"
  type        = string
}

variable "environment" {
  description = "Environment name"
  type        = string
}

variable "tags" {
  description = "Additional tags"
  type        = map(string)
  default     = {}
}