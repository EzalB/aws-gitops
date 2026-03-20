resource "kubernetes_namespace" "argocd" {
  metadata {
    name = "argocd"
  }
  depends_on = [module.eks]
}

resource "helm_release" "argocd" {
  name       = "argocd"
  repository = "https://argoproj.github.io/argo-helm"
  chart      = "argo-cd"
  version    = "6.7.1"
  namespace  = kubernetes_namespace.argocd.metadata[0].name

  wait = true

  # Optional adjustments for a small free tier showcase cluster
  values = [
    <<-EOT
    controller:
      replicas: 1
      resources:
        requests:
          cpu: 50m
          memory: 256Mi
        limits:
          cpu: 500m
          memory: 512Mi
    server:
      replicas: 1
      service:
        type: LoadBalancer # Automatically creates an AWS Classic Load Balancer for UI access
      resources:
        requests:
          cpu: 50m
          memory: 128Mi
        limits:
          cpu: 500m
          memory: 256Mi
    repoServer:
      replicas: 1
      resources:
        requests:
          cpu: 50m
          memory: 128Mi
        limits:
          cpu: 500m
          memory: 256Mi
    applicationSet:
      replicas: 1
    dex:
      enabled: false # Disabled to save resources, basic auth is enough for showcase
    EOT
  ]
}

resource "kubernetes_manifest" "nginx_app_sync" {
  depends_on = [helm_release.argocd]

  manifest = {
    apiVersion = "argoproj.io/v1alpha1"
    kind       = "Application"
    metadata = {
      name      = "gitops-nginx-app"
      namespace = kubernetes_namespace.argocd.metadata[0].name
    }
    spec = {
      project = "default"
      source = {
        # USER MUST REPLACE THIS WITH THEIR REPO URL
        repoURL        = "https://github.com/your-github-username/argocd-nginx-showcase.git" 
        targetRevision = "HEAD"
        path           = "helm/nginx-app"
      }
      destination = {
        server    = "https://kubernetes.default.svc"
        namespace = "default"
      }
      syncPolicy = {
        automated = {
          prune    = true
          selfHeal = true
        }
        syncOptions = [
          "CreateNamespace=true"
        ]
      }
    }
  }
}
