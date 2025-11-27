locals {
  bootstrap_argocd = var.enable_argocd_bootstrap
}

resource "helm_release" "argocd" {
  count = local.bootstrap_argocd ? 1 : 0

  name       = "argocd"
  repository = "https://argoproj.github.io/argo-helm"
  chart      = "argo-cd"
  version    = "5.53.9"

  namespace        = "argocd"
  create_namespace = true

  values = [
    <<-YAML
    server:
      service:
        type: LoadBalancer
    configs:
      params:
        server.insecure: true
    YAML
  ]

  depends_on = [module.eks]
}

data "kubernetes_service" "argocd_server" {
  count = local.bootstrap_argocd ? 1 : 0

  metadata {
    name      = "argocd-server"
    namespace = helm_release.argocd[0].namespace
  }

  depends_on = [helm_release.argocd]
}

resource "kubernetes_namespace" "demo" {
  count = local.bootstrap_argocd ? 1 : 0

  metadata {
    name = var.sample_app_namespace
  }
}

resource "kubernetes_manifest" "sample_app" {
  count = local.bootstrap_argocd ? 1 : 0

  manifest = {
    "apiVersion" = "argoproj.io/v1alpha1"
    "kind"       = "Application"
    "metadata" = {
      "name"      = "${var.name_prefix}-sample-app"
      "namespace" = helm_release.argocd[0].namespace
    }
    "spec" = {
      "project" = "default"
      "source" = {
        "repoURL"        = var.git_repo_url
        "targetRevision" = var.git_repo_revision
        "path"           = "apps/sample-app"
      }
      "destination" = {
        "server"    = "https://kubernetes.default.svc"
        "namespace" = var.sample_app_namespace
      }
      "syncPolicy" = {
        "automated" = {
          "prune"    = true
          "selfHeal" = true
        }
        "syncOptions" = [
          "CreateNamespace=true"
        ]
      }
    }
  }

  depends_on = [helm_release.argocd, kubernetes_namespace.demo]
}
