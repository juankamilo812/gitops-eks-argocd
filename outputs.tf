output "cluster_name" {
  description = "EKS cluster name."
  value       = module.eks.cluster_name
}

output "cluster_region" {
  description = "AWS region used."
  value       = var.region
}

output "argocd_server_hostname" {
  description = "External hostname for the Argo CD server LoadBalancer."
  value = length(data.kubernetes_service.argocd_server) > 0 ? try(
    data.kubernetes_service.argocd_server[0].status[0].load_balancer[0].ingress[0].hostname,
    null
  ) : null
}

output "sample_app_namespace" {
  description = "Namespace where the sample application is deployed."
  value       = var.sample_app_namespace
}
