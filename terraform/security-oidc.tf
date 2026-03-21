# # OIDC Provider for GitHub Actions
# resource "aws_iam_openid_connect_provider" "github" {
#   url             = "https://token.actions.githubusercontent.com"
#   client_id_list  = ["sts.amazonaws.com"]
#   thumbprint_list = ["6938fd4d98bab03faadb97b34396831e3780aea1", "1c58a3a8518e8759bf075b76b750d4f2df264fcd"] # Known GitHub Actions thumbprints
# }

# # IAM Role assumed by GitHub Actions
# resource "aws_iam_role" "github_actions" {
#   name = "GitHubActionsECRPushRole"

#   assume_role_policy = jsonencode({
#     Version = "2012-10-17"
#     Statement = [
#       {
#         Action = "sts:AssumeRoleWithWebIdentity"
#         Effect = "Allow"
#         Principal = {
#           Federated = aws_iam_openid_connect_provider.github.arn
#         }
#         Condition = {
#           StringLike = {
#             "token.actions.githubusercontent.com:sub" : "repo:${var.github_org}/${var.github_repo}:ref:refs/heads/main"
#           }
#           StringEquals = {
#             "token.actions.githubusercontent.com:aud" : "sts.amazonaws.com"
#           }
#         }
#       }
#     ]
#   })
# }

# # Policy to allow ECR login and push
# resource "aws_iam_policy" "ecr_push" {
#   name        = "GitHubActionsECRPushPolicy"
#   description = "Policy for GitHub Actions to push to ECR"

#   policy = jsonencode({
#     Version = "2012-10-17"
#     Statement = [
#       {
#         Effect = "Allow"
#         Action = [
#           "ecr:GetAuthorizationToken"
#         ]
#         Resource = "*"
#       },
#       {
#         Effect = "Allow"
#         Action = [
#           "ecr:BatchCheckLayerAvailability",
#           "ecr:GetDownloadUrlForLayer",
#           "ecr:GetRepositoryPolicy",
#           "ecr:DescribeRepositories",
#           "ecr:ListImages",
#           "ecr:DescribeImages",
#           "ecr:BatchGetImage",
#           "ecr:InitiateLayerUpload",
#           "ecr:UploadLayerPart",
#           "ecr:CompleteLayerUpload",
#           "ecr:PutImage"
#         ]
#         Resource = aws_ecr_repository.app.arn
#       }
#     ]
#   })
# }

# resource "aws_iam_role_policy_attachment" "github_actions_ecr" {
#   role       = aws_iam_role.github_actions.name
#   policy_arn = aws_iam_policy.ecr_push.arn
# }

