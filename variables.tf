# general

variable "project_name" {
  type        = string
  description = "project name, used for prefixing all the resources"
}

variable "domain_name" {
  type        = string
  description = "domain name, such as example.com"
}

variable "region" {
  type        = string
  description = "AWS region"
}


# VPC

variable "vpc_cidr" {
  description = "CIDR of the VPC"
  default     = "10.0.0.0/16"
  type        = string
}

variable "vpc_private_subnets" {
  description = "private subnets"
  default     = ["10.0.1.0/24", "10.0.2.0/24", "10.0.3.0/24"]
  type        = list(string)
}

variable "vpc_public_subnets" {
  description = "public subnets"
  default     = ["10.0.101.0/24", "10.0.102.0/24", "10.0.103.0/24"]
  type        = list(string)
}


# EKS

variable "k8s_version" {
  description = "k8s cluster version"
  default     = "1.21"
  type        = string
}

variable "k8s_worker_group_instance_type" {
  description = "instance type of the main worker group"
  default     = "t2.large"
  type        = string
}

variable "k8s_worker_group_asg_max_size" {
  description = "max size of ASG for main worker group"
  default     = 4
  type        = string
}
