data "terraform_remote_state" "db" {
  backend = "s3"

  config = {
    bucket = var.db_infra_state_bucket
    key    = var.db_infra_state_key
    region = var.db_infra_state_region
  }
}

locals {
  name_prefix = "${var.project_name}-${var.environment}"
  db_outputs  = data.terraform_remote_state.db.outputs

  # Exige apply completo do db-infra (VPC + RDS). Apply parcial/antigo
  # falha com "Unsupported attribute" (ex.: sem public_subnet_ids).
  vpc_id             = local.db_outputs.vpc_id
  vpc_cidr           = local.db_outputs.vpc_cidr
  private_subnet_ids = local.db_outputs.private_subnet_ids
  public_subnet_ids  = local.db_outputs.public_subnet_ids
  rds_sg_id          = local.db_outputs.rds_security_group_id
}

check "db_infra_outputs_ready" {
  assert {
    condition = (
      try(length(local.public_subnet_ids), 0) > 0 &&
      try(length(local.private_subnet_ids), 0) > 0 &&
      try(local.rds_sg_id, "") != ""
    )
    error_message = "Remote state do db-infra incompleto (faltam subnets/RDS SG). Rode o apply do tech-challenge-db-infra em homolog antes do k8s-infra."
  }
}
