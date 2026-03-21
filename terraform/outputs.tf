output "ecr_repository_url" {
  description = "The URL of the ECR repository"
  value       = aws_ecr_repository.app.repository_url
}

output "github_actions_ci_role_arn" {
  description = "The ARN of the IAM role used by CI to push to ECR"
  value       = aws_iam_role.github_actions.arn
}

output "github_actions_terraform_role_arn" {
  description = "The ARN of the IAM role used by CD to provision Terraform"
  value       = aws_iam_role.github_actions.arn # Assuming single role mapping as reverted by user previously
}

output "eks_cluster_name" {
  description = "The name of the EKS cluster"
  value       = module.eks.cluster_name
}

output "eks_cluster_endpoint" {
  description = "Endpoint for EKS control plane"
  value       = module.eks.cluster_endpoint
}

output "vpc_id" {
  description = "The ID of the VPC"
  value       = module.vpc.vpc_id
}
