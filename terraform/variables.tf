variable "aws_region" {
  description = "AWS Region for deployment"
  type        = string
  default     = "us-east-1"
}

variable "github_org" {
  description = "GitHub Organization or Username"
  type        = string
  default     = "EzalB" # USER SHOULD UPDATE THIS
}

variable "github_repo" {
  description = "GitHub Repository Name"
  type        = string
  default     = "argocd-nginx-showcase" # USER SHOULD UPDATE THIS
}
