data "terraform_remote_state" "db" {
  backend = "s3"

  config = {
    bucket = var.db_infra_state_bucket
    key    = var.db_infra_state_key
    region = var.db_infra_state_region
  }
}

locals {
  name_prefix        = "${var.project_name}-${var.environment}"
  vpc_id             = data.terraform_remote_state.db.outputs.vpc_id
  private_subnet_ids = data.terraform_remote_state.db.outputs.private_subnet_ids
  public_subnet_ids  = data.terraform_remote_state.db.outputs.public_subnet_ids
  rds_sg_id          = data.terraform_remote_state.db.outputs.rds_security_group_id
}
