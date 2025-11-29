variable "region" {
  description = "AWS region where the EKS cluster will run."
  type        = string
  default     = "us-east-1"
}

variable "aws_profile" {
  description = "AWS CLI profile for authentication (supports SSO)."
  type        = string
  default     = "vop-dev"
}

variable "name_prefix" {
  description = "Prefix used for resource naming."
  type        = string
  default     = "gitops-eks"
}

variable "cluster_name" {
  description = "EKS cluster name."
  type        = string
  default     = "gitops-eks"
}

variable "kubernetes_version" {
  description = "EKS control plane version."
  type        = string
  default     = "1.30"
}

variable "vpc_cidr" {
  description = "CIDR block for the VPC."
  type        = string
  default     = "10.0.0.0/16"
}

variable "public_subnets" {
  description = "Public subnet CIDRs."
  type        = list(string)
  default     = ["10.0.0.0/24", "10.0.1.0/24", "10.0.2.0/24"]
}

variable "private_subnets" {
  description = "Private subnet CIDRs."
  type        = list(string)
  default     = ["10.0.10.0/24", "10.0.11.0/24", "10.0.12.0/24"]
}

variable "git_repo_url" {
  description = "Git repository URL that Argo CD will watch."
  type        = string
  default     = "https://github.com/juankamilo812/gitops-eks-argocd.git"
}

variable "git_repo_revision" {
  description = "Branch or tag Argo CD tracks."
  type        = string
  default     = "main"
}

variable "sample_app_namespace" {
  description = "Kubernetes namespace for the sample application."
  type        = string
  default     = "demo"
}

variable "enable_argocd_bootstrap" {
  description = "Instala Argo CD y la aplicación de ejemplo. Ponlo en true después de que el clúster esté creado y accesible."
  type        = bool
  default     = false
}

variable "admin_cidr" {
  description = "CIDR permitido para acceso SSH a nodos y comunicación de administración (tu IP pública)."
  type        = string
  default     = "201.233.190.31/32"
}

variable "admin_iam_principal_arn" {
  description = "ARN del rol o usuario IAM que tendrá acceso admin al API de Kubernetes (EKS access entry)."
  type        = string
  default     = "arn:aws:iam::412381767274:role/aws-reserved/sso.amazonaws.com/eu-west-2/AWSReservedSSO_GFTAdministratorAccess_142b237aadf1415b"
}
