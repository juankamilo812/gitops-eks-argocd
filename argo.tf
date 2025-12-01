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
    installCRDs: true
    applicationSet:
      enabled: true
      installCRDs: true
    server:
      service:
        type: LoadBalancer
        loadBalancerSourceRanges:
          - ${var.admin_cidr}
    configs:
      params:
        server.insecure: true
    extraObjects:
      - apiVersion: argoproj.io/v1alpha1
        kind: ApplicationSet
        metadata:
          name: ${var.name_prefix}-apps
          namespace: argocd
        spec:
          generators:
            - git:
                repoURL: ${var.git_repo_url}
                revision: ${var.git_repo_revision}
                directories:
                  - path: apps/*
          template:
            metadata:
              name: '{{"{{path.basename}}"}}'
            spec:
              project: default
              source:
                repoURL: ${var.git_repo_url}
                targetRevision: ${var.git_repo_revision}
                path: '{{"{{path}}"}}'
              destination:
                server: https://kubernetes.default.svc
                namespace: '{{"{{path.basename}}"}}'
              syncPolicy:
                automated:
                  prune: true
                  selfHeal: true
                syncOptions:
                  - CreateNamespace=true
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
