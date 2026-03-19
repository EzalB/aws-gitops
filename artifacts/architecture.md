# Production-Grade GitOps Platform for NGINX on AWS EKS

## 1. High-Level Architecture

The architecture represents a scalable, secure, and fully automated GitOps lifecycle using GitHub Actions for Continuous Integration (CI) and ArgoCD for Continuous Deployment (CD). 

**Key Components & Flow:**
1. **Source Control (GitHub):** Holds Application code (`app/`), Helm charts (`helm/`), and Infrastructure code (`terraform/`).
2. **CI Pipeline (GitHub Actions):** 
   - Uses **OIDC** to assume an AWS IAM Role securely (no long-lived credentials).
   - Builds the NGINX Docker image.
   - Pushes the image to **Amazon ECR**.
   - Commits the new Docker image tag back to the Helm chart's `values.yaml` in the repository.
3. **AWS Infrastructure (Terraform):**
   - **VPC** with public/private subnets.
   - **Amazon EKS** cluster with an OIDC provider associated.
   - **IRSA (IAM Roles for Service Accounts):** Provides fine-grained, secure access to AWS resources (e.g., pulling ECR images, interacting with ALBs) without mounting AWS credentials into pods.
   - Bootstraps ArgoCD directly into the cluster.
4. **GitOps CD (ArgoCD):**
   - Continuously monitors the GitHub repository.
   - Automatically synchronizes the EKS cluster state with the Helm configurations defined in Git.

*Note on AWS Free Tier:* EKS control plane has a flat hourly fee (~$73/month) and is not part of the AWS Free Tier. To minimize costs, the architecture will use Spot Instances or small instance types (`t3.micro`/`t3.small`) for the EKS managed node groups.

## 2. Folder Structure

Adopting a monorepo approach for this showcase. In a real enterprise scenario, this could be split into separate App and Infra repositories.

```text
.
├── .github/
│   └── workflows/
│       ├── ci.yaml               # Builds NGINX, pushes to ECR, updates Helm values
│       └── terraform.yaml        # TF linting, planning, and applying infrastructure
├── terraform/
│   ├── backend.tf                # S3 state and DynamoDB locks setup
│   ├── providers.tf              # AWS and Helm providers mapped
│   ├── network.tf                # VPC, subnets, NAT Gateways
│   ├── eks.tf                    # EKS Cluster, Node Groups (t3.small/spot)
│   ├── security-oidc.tf          # GitHub OIDC Provider & IRSA configurations
│   └── argocd.tf                 # ArgoCD initial bootstrap via Helm
├── app/
│   ├── Dockerfile                # Production-ready multi-stage unprivileged NGINX build
│   ├── nginx.conf                # Custom NGINX configuration
│   └── html/                     # Static website content
└── helm/
    └── nginx-app/
        ├── Chart.yaml            # Semantic versioning for the Helm chart
        ├── values.yaml           # App configuration and dynamically updated image tag
        └── templates/
            ├── deployment.yaml   # NGINX Deployment
            ├── service.yaml      # Kubernetes Service definition
            ├── ingress.yaml      # Ingress definition (e.g., AWS ALB Ingress)
            └── rbac.yaml         # ServiceAccount with IRSA annotations
```

## 3. Implementation Plan

1. **Phase 1: Security & Foundation (Terraform)**
   - Configure AWS OIDC Identity Provider for GitHub Actions.
   - Create IAM Roles that GitHub Actions can assume.
   - Set up an S3 bucket and DynamoDB table for Terraform state.

2. **Phase 2: Infrastructure Provisioning (Terraform)**
   - Create a VPC with private subnets for EKS nodes and public subnets for load balancers.
   - Provision the EKS Cluster with OIDC integrated.
   - Create a Managed Node Group using Spot instances (`t3.small` / `t3.medium`) to maximize Free Tier limits and reduce costs.

3. **Phase 3: Automated Platform Bootstrapping**
   - Use the Terraform Helm provider to install NGINX Ingress Controller / AWS Load Balancer Controller.
   - Use the Terraform Helm provider to install ArgoCD into the `argocd` namespace.

4. **Phase 4: CI Pipeline Setup (GitHub Actions)**
   - Draft `ci.yaml` to trigger on changes to `app/**`.
   - Steps: Checkout -> Configure AWS Credentials (via OIDC) -> Login to ECR -> Build & Push Docker image -> Replace image tag in `helm/nginx-app/values.yaml` -> Commit & Push changes.

5. **Phase 5: CD Pipeline Setup (ArgoCD)**
   - Define an ArgoCD `Application` manifest that points to the `helm/nginx-app` directory in the repository.
   - Apply the Application manifest to let ArgoCD take over deployment synchronization.

## 4. ArgoCD Usage Design/Pattern

- **Helm-native GitOps:** ArgoCD is configured to read standard Helm charts directly from the Git repository. It renders the templates and applies the exact manifests.
- **Automated Sync & Drift Detection:**
  - `Automated Sync`: Enabled. ArgoCD will deploy as soon as GitHub Actions updates the image tag in `values.yaml`.
  - `Self-Heal`: Enabled. If someone manually changes a resource via `kubectl`, ArgoCD instantly reverts it to match Git boundaries to strictly prevent configuration drift.
  - `Prune`: Enabled. Resources deleted from Git are automatically removed from the cluster.
- **App of Apps Pattern (Advanced Extension):** For managing multiple microservices and cluster addons (like Prometheus, Ingress Controller), a single root ArgoCD `Application` can be configured that loads further `Application` definitions.

## 5. Advanced Strategies or Features

- **Progressive Delivery (Argo Rollouts):** Transition from standard core Kubernetes `Deployment` object to a `Rollout` object to support Canary or Blue/Green deployments. Argo Rollouts incrementally shifts traffic to the new NGINX version and can dynamically pause or abort if prometheus metrics degrade.
- **Automated Image Updates (ArgoCD Image Updater):** Instead of having GitHub Actions commit the updated `values.yaml` back to the Git source, `argocd-image-updater` can be installed in EKS. It securely monitors the ECR repository via IRSA, fetching the latest tags, and applies application updates natively without write access to the Git repo.
- **Secrets Management (External Secrets Operator):** Prevent hardcoding sensitive values anywhere in Git. EKS can use an OIDC-backed IAM role (IRSA) to allow an External Secrets Operator to securely inject secrets directly from AWS Secrets Manager into Kubernetes Secrets natively.
- **Auto-Scaling (Karpenter or Cluster Autoscaler):** Provision dynamic instances automatically, adding or removing EKS worker nodes dynamically based on pending NGINX pod resources. Follows Free Tier parameters.
- **Service Mesh (Istio / Linkerd):** Introduce mTLS across components, complex traffic routing capabilities, and robust internal observability natively without altering the primary NGINX pod definitions.
