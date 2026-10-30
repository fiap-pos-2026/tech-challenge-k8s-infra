# AWS Academy (voclabs): iam:CreateRole é negado.
# Alguns labs têm LabEksClusterRole / LabEksNodeRole; outros só LabRole.
# Auto-detecta roles cujo nome começa com "Lab"; pin opcional via variáveis.

data "aws_iam_roles" "lab" {
  name_regex = "(?i)^Lab"
}

locals {
  lab_role_names = sort(tolist(data.aws_iam_roles.lab.names))

  auto_cluster_role = (
    contains(local.lab_role_names, "LabEksClusterRole") ? "LabEksClusterRole" :
    contains(local.lab_role_names, "LabRole") ? "LabRole" :
    try(local.lab_role_names[0], null)
  )

  auto_node_role = (
    contains(local.lab_role_names, "LabEksNodeRole") ? "LabEksNodeRole" :
    contains(local.lab_role_names, "LabRole") ? "LabRole" :
    try(local.lab_role_names[0], null)
  )

  eks_cluster_role_name = coalesce(var.eks_cluster_role_name, local.auto_cluster_role)
  eks_node_role_name    = coalesce(var.eks_node_role_name, local.auto_node_role)
}

check "academy_lab_iam_roles" {
  assert {
    condition = (
      local.eks_cluster_role_name != null &&
      local.eks_node_role_name != null
    )
    error_message = "Nenhuma IAM role Lab* encontrada (ListRoles). Visíveis: [${join(", ", local.lab_role_names)}]. Defina eks_cluster_role_name / eks_node_role_name ou verifique o lab."
  }
}

data "aws_iam_role" "eks_cluster" {
  name = local.eks_cluster_role_name
}

data "aws_iam_role" "eks_node" {
  name = local.eks_node_role_name
}

locals {
  eks_cluster_role_arn = data.aws_iam_role.eks_cluster.arn
  eks_node_role_arn    = data.aws_iam_role.eks_node.arn
}
