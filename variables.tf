variable "aws_region" {
  description = "Região AWS (Academy Learner Lab: us-east-1)"
  type        = string
  default     = "us-east-1"
}

variable "project_name" {
  description = "Prefixo de nomes dos recursos"
  type        = string
  default     = "tech-challenge"
}

variable "environment" {
  description = "Ambiente (homolog | prod)"
  type        = string
  default     = "homolog"
}

variable "db_infra_state_bucket" {
  description = "Bucket S3 do state do tech-challenge-db-infra"
  type        = string
}

variable "db_infra_state_key" {
  description = "Key do state do db-infra"
  type        = string
  default     = "db-infra/homolog/terraform.tfstate"
}

variable "db_infra_state_region" {
  description = "Região do bucket de state do db-infra (deve coincidir com AWS_REGION / Academy)"
  type        = string
  default     = "us-east-1"
}

variable "eks_cluster_role_name" {
  description = "Pin opcional (nome exato no IAM). null = auto via regex *LabEksClusterRole*."
  type        = string
  default     = null
  nullable    = true
}

variable "eks_node_role_name" {
  description = "Pin opcional (nome exato). null = auto via regex *LabEksNodeRole*."
  type        = string
  default     = null
  nullable    = true
}

variable "kubernetes_version" {
  description = "Versão do Kubernetes no EKS"
  type        = string
  default     = "1.31"
}

variable "node_instance_types" {
  description = "Tipos de instância do node group"
  type        = list(string)
  default     = ["t3.medium"]
}

variable "node_desired_size" {
  description = "Quantidade desejada de nodes"
  type        = number
  default     = 2
}

variable "node_min_size" {
  description = "Mínimo de nodes"
  type        = number
  default     = 1
}

variable "node_max_size" {
  description = "Máximo de nodes (HPA do cluster)"
  type        = number
  default     = 4
}

variable "auth_lambda_invoke_arn" {
  description = "Invoke ARN da Lambda de autenticação (preencher após o deploy do auth-lambda). Vazio = rota /auth ainda sem integração."
  type        = string
  default     = ""
}

variable "core_nlb_listener_arn" {
  description = "Override opcional do ARN do listener NLB do core. Vazio = discovery pela tag kubernetes.io/service-name=tech-challenge/core (após o Service LoadBalancer existir)."
  type        = string
  default     = ""
}

variable "core_k8s_service_name" {
  description = "Tag kubernetes.io/service-name do Service que cria o NLB (namespace/name)."
  type        = string
  default     = "tech-challenge/core"
}

variable "core_nlb_listener_port" {
  description = "Porta do listener TCP no NLB do core (Service port)."
  type        = number
  default     = 8080
}
