# AWS Academy (voclabs): iam:CreateRole e negado.
# Roles EKS do lab costumam vir com prefixo aleatorio + LabEksClusterRole / LabEksNodeRole.
# Pin opcional via variaveis (nome exato do console).

data "aws_iam_roles" "eks_cluster_candidates" {
  name_regex = "(?i).*LabEksClusterRole.*"
}

data "aws_iam_roles" "eks_node_candidates" {
  name_regex = "(?i).*LabEksNodeRole.*"
}

data "aws_iam_roles" "lab_role_fallback" {
  name_regex = "(?i)^LabRole$"
}

locals {
  cluster_candidates = sort(tolist(data.aws_iam_roles.eks_cluster_candidates.names))
  node_candidates    = sort(tolist(data.aws_iam_roles.eks_node_candidates.names))
  lab_role_names     = sort(tolist(data.aws_iam_roles.lab_role_fallback.names))

  auto_cluster_role = try(local.cluster_candidates[0], try(local.lab_role_names[0], null))
  auto_node_role    = try(local.node_candidates[0], try(local.lab_role_names[0], null))

  eks_cluster_role_name = coalesce(var.eks_cluster_role_name, local.auto_cluster_role)
  eks_node_role_name    = coalesce(var.eks_node_role_name, local.auto_node_role)
}

check "academy_lab_iam_roles" {
  assert {
    condition = (
      local.eks_cluster_role_name != null &&
      local.eks_node_role_name != null
    )
    error_message = <<-EOT
      Nenhuma IAM role EKS do Academy encontrada.
      Cluster candidates (*LabEksClusterRole*): [${join(", ", local.cluster_candidates)}]
      Node candidates (*LabEksNodeRole*): [${join(", ", local.node_candidates)}]
      LabRole: [${join(", ", local.lab_role_names)}]
      Defina eks_cluster_role_name / eks_node_role_name com o nome exato do console.
    EOT
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
