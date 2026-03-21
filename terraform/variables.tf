variable "aws_region" {
  description = "AWS Region for deployment"
  type        = string
  default     = "us-east-1"
}

variable "github_org" {
  description = "GitHub Organization or Username"
  type        = string
  default     = "EzalB"
}

variable "github_repo" {
  description = "GitHub Repository Name"
  type        = string
  default     = "aws-gitops"
}

variable "project_name" {
  description = "Name for the project (prefixes resources)"
  type        = string
  default     = "aws-gitops"
}

variable "environment" {
  description = "Environment name (e.g. production, staging)"
  type        = string
  default     = "production"
}

variable "vpc_cidr" {
  description = "CIDR block for the VPC"
  type        = string
  default     = "10.0.0.0/16"
}

variable "cluster_version" {
  description = "Kubernetes version for EKS cluster"
  type        = string
  default     = "1.29"
}

variable "node_instance_types" {
  description = "List of EC2 instance types for the EKS node group"
  type        = list(string)
  default     = ["t3.small", "t3.medium"]
}

variable "public_access_cidrs" {
  description = "CIDRs that can access the EKS cluster API endpoint natively"
  type        = list(string)
  default     = ["0.0.0.0/0"] # TODO: Restrict to VPN/Corporate CIDR in production
}

variable "argocd_chart_version" {
  description = "Helm chart version for ArgoCD"
  type        = string
  default     = "6.7.1"
}
