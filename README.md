# tech-challenge-k8s-infra

Terraform do cluster Kubernetes e da porta de entrada HTTP da oficina.

O que sobe aqui:

- Amazon EKS (control plane + node group)
- Security groups (incluindo liberação dos nodes para o Postgres na 5432)
- API Gateway HTTP API (depois ligamos `/auth` na Lambda e `/core` na app)

A VPC e o RDS vêm do [tech-challenge-db-infra](https://github.com/fiap-pos-2026/tech-challenge-db-infra) via remote state. A app está em [tech-challenge-core](https://github.com/fiap-pos-2026/tech-challenge-core); a auth serverless em [tech-challenge-auth-lambda](https://github.com/fiap-pos-2026/tech-challenge-auth-lambda).

```text
Internet
   │
   ▼
API Gateway ──► app no EKS
   │
   └──► Lambda (login por CPF)
```

## Stack

| Item | Valor |
|---|---|
| Nuvem | AWS (`us-east-1` no lab da FIAP) |
| Cluster | EKS |
| IAM no lab | roles prontas `*LabEksClusterRole*` / `*LabEksNodeRole*` (não criamos role no Terraform) |
| Entrada | API Gateway HTTP API |
| IaC | Terraform ≥ 1.6 |

No lab, `iam:CreateRole` é bloqueado. O código procura as roles EKS que a academia já deixa na conta; se precisar, você fixa o nome exato no tfvars.

## Outputs

Repositório público: **não** versionamos endpoint do EKS, URL do Gateway, IDs de security group nem nomes longos de role.

```bash
terraform output
```

Para o kubectl (com o lab ativo):

```bash
aws eks update-kubeconfig --name "$(terraform output -raw cluster_name)" --region us-east-1
kubectl get nodes
```

## Como rodar local

1. `db-infra` já aplicado e state acessível.
2. Preencha bucket/tabela e aponte o remote state do banco:

```bash
cp terraform.tfvars.example terraform.tfvars
cp backend.hcl.example backend.hcl
terraform init -backend-config=backend.hcl
terraform plan -var-file=terraform.tfvars
terraform apply -var-file=terraform.tfvars
```

Não commite `terraform.tfvars`, `backend.hcl` nem state.

## CI

PR: fmt, validate, plan.  
`main` (ou `workflow_dispatch`): apply em homolog.

Secrets: access key, secret, session token, bucket e tabela de lock.

## Custo

EKS control plane e os nodes pesam bastante, somados ao NAT do `db-infra`. Fora de uso, destrua **este** stack primeiro e o `db-infra` depois. Confira o crédito no portal do lab.
