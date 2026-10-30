# AWS Academy Learner Lab (voclabs): iam:CreateRole é negado.
# Usar roles pré-criadas do lab (console EKS → Cluster IAM role / Node role).
# Conta própria: sobrescrever via TF_VAR_eks_cluster_role_name / TF_VAR_eks_node_role_name
# com roles que você criar fora do lab.

data "aws_iam_role" "eks_cluster" {
  name = var.eks_cluster_role_name
}

data "aws_iam_role" "eks_node" {
  name = var.eks_node_role_name
}

locals {
  eks_cluster_role_arn = data.aws_iam_role.eks_cluster.arn
  eks_node_role_arn    = data.aws_iam_role.eks_node.arn
}
