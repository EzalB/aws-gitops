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
  version    = var.argocd_chart_version
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
        # Strict Security: ArgoCD is fundamentally internal tooling.
        # NEVER expose this on a public LoadBalancer without SSO/Oauth2 Proxy.
        # Access via: kubectl port-forward svc/argocd-server -n argocd 8080:443
        type: ClusterIP
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
        repoURL        = "https://github.com/${var.github_org}/${var.github_repo}.git"
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
