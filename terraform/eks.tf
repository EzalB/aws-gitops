module "eks" {
  source  = "terraform-aws-modules/eks/aws"
  version = "~> 20.0"

  cluster_name    = "${local.name}-cluster"
  cluster_version = "1.29"

  vpc_id                   = module.vpc.vpc_id
  subnet_ids               = module.vpc.private_subnets
  control_plane_subnet_ids = module.vpc.intra_subnets

  # Enable OIDC for IRSA (IAM Roles for Service Accounts)
  cluster_endpoint_public_access = true
  enable_irsa                    = true

  # Free Tier Friendly Managed Node Group
  eks_managed_node_groups = {
    showcase_nodes = {
      min_size     = 1
      max_size     = 3
      desired_size = 2

      # Small instances for cost optimization
      instance_types = ["t3.small", "t3.medium"]
      
      # Use Spot Instances to significantly reduce EKS compute costs
      capacity_type  = "SPOT"
      
      labels = {
        Environment = "showcase"
        GithubRepo  = "argocd-nginx"
      }
      
      update_config = {
        max_unavailable = 1
      }
      
      # Additional IAM policies for Node Group
      iam_role_additional_policies = {
        AmazonSSMManagedInstanceCore = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
      }
    }
  }

  access_entries = {
    # Allow the creator full access to the cluster via their AWS credentials
    creator = {
      kubernetes_groups = []
      principal_arn     = data.aws_caller_identity.current.arn

      policy_associations = {
        admin = {
          policy_arn = "arn:aws:eks::aws:cluster-access-policy/AmazonEKSClusterAdminPolicy"
          access_scope = {
            type       = "cluster"
          }
        }
      }
    }
  }
}

data "aws_caller_identity" "current" {}
