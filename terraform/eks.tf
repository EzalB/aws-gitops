module "eks" {
  source  = "terraform-aws-modules/eks/aws"
  version = "~> 20.0"

  cluster_name    = "${var.project_name}-${var.environment}-cluster"
  cluster_version = var.cluster_version

  vpc_id                   = module.vpc.vpc_id
  subnet_ids               = module.vpc.private_subnets
  control_plane_subnet_ids = module.vpc.intra_subnets

  # Strict Security: Restrict public endpoint to known IPs (e.g., VPN/Bastion)
  # For showcase purposes it remains open, but in production, replace with corporate CIDRs.
  cluster_endpoint_public_access       = true
  cluster_endpoint_public_access_cidrs = var.public_access_cidrs

  # Strict Security: Cluster Audit Logging
  cluster_enabled_log_types = ["api", "audit", "authenticator", "controllerManager", "scheduler"]

  # Strict Security: Kubernetes Secrets KMS Encryption
  create_kms_key = true
  cluster_encryption_config = {
    resources = ["secrets"]
  }

  enable_irsa = true

  # Free Tier Friendly Managed Node Group
  eks_managed_node_groups = {
    showcase_nodes = {
      min_size     = 1
      max_size     = 3
      desired_size = 2

      # Small instances for cost optimization
      instance_types = var.node_instance_types

      # Use Spot Instances to significantly reduce EKS compute costs
      capacity_type = "SPOT"

      labels = {
        Environment = var.environment
        GithubRepo  = var.github_repo
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
            type = "cluster"
          }
        }
      }
    }
  }
}

data "aws_caller_identity" "current" {}

