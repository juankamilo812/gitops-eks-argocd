data "aws_iam_policy_document" "cluster_autoscaler_assume" {
  statement {
    actions = ["sts:AssumeRoleWithWebIdentity"]

    principals {
      type        = "Federated"
      identifiers = [module.eks.oidc_provider_arn]
    }

    condition {
      test     = "StringEquals"
      variable = "${replace(module.eks.oidc_provider, "https://", "")}:sub"
      values   = ["system:serviceaccount:kube-system:cluster-autoscaler"]
    }

    condition {
      test     = "StringEquals"
      variable = "${replace(module.eks.oidc_provider, "https://", "")}:aud"
      values   = ["sts.amazonaws.com"]
    }
  }
}

data "aws_iam_policy_document" "cluster_autoscaler" {
  statement {
    actions = [
      "autoscaling:DescribeAutoScalingGroups",
      "autoscaling:DescribeAutoScalingInstances",
      "autoscaling:DescribeLaunchConfigurations",
      "autoscaling:DescribeScalingActivities",
      "autoscaling:DescribeTags",
      "autoscaling:SetDesiredCapacity",
      "autoscaling:TerminateInstanceInAutoScalingGroup",
      "autoscaling:UpdateAutoScalingGroup",
      "ec2:DescribeInstanceTypes",
      "ec2:DescribeLaunchTemplateVersions",
      "ec2:DescribeImages",
      "ec2:DescribeInstances",
      "eks:DescribeNodegroup",
      "eks:DescribeCluster",
    ]

    resources = ["*"]
  }
}

resource "aws_iam_role" "cluster_autoscaler" {
  name               = "${var.name_prefix}-cluster-autoscaler"
  assume_role_policy = data.aws_iam_policy_document.cluster_autoscaler_assume.json
}

resource "aws_iam_role_policy" "cluster_autoscaler" {
  name   = "${var.name_prefix}-cluster-autoscaler"
  role   = aws_iam_role.cluster_autoscaler.id
  policy = data.aws_iam_policy_document.cluster_autoscaler.json
}

# resource "helm_release" "cluster_autoscaler" {
#   name       = "cluster-autoscaler"
#   repository = "https://kubernetes.github.io/autoscaler"
#   chart      = "cluster-autoscaler"
#   version    = "9.37.0"
#
#   namespace = "kube-system"
#
#   values = [
#     <<-YAML
#     autoDiscovery:
#       clusterName: ${var.cluster_name}
#     awsRegion: ${var.region}
#     rbac:
#       serviceAccount:
#         create: true
#         name: cluster-autoscaler
#         annotations:
#           eks.amazonaws.com/role-arn: ${aws_iam_role.cluster_autoscaler.arn}
#     extraArgs:
#       skip-nodes-with-local-storage: false
#       scan-interval: 10s
#       balance-similar-node-groups: true
#       skip-nodes-with-system-pods: false
#     tolerations:
#       - effect: NoSchedule
#         key: node-role.kubernetes.io/control-plane
#         operator: Exists
#       - key: CriticalAddonsOnly
#         operator: Exists
#     affinity:
#       podAntiAffinity:
#         preferredDuringSchedulingIgnoredDuringExecution:
#           - weight: 100
#             podAffinityTerm:
#               labelSelector:
#                 matchExpressions:
#                   - key: app.kubernetes.io/name
#                     operator: In
#                     values:
#                       - cluster-autoscaler
#               topologyKey: kubernetes.io/hostname
#     YAML
#   ]
#
#   depends_on = [module.eks, aws_iam_role_policy.cluster_autoscaler]
# }
