# tech-challenge-k8s-infra

Infraestrutura como código do **cluster Kubernetes** e da **entrada HTTP** da Fase 3 (The Java Garage).

Provisiona via **Terraform**:

- Cluster **Amazon EKS** (control plane + node group)
- Integração com a VPC criada em `tech-challenge-db-infra` (remote state)
- Security groups liberando tráfego dos nodes para o RDS
- Base de **API Gateway HTTP API** (rotas para a app e para a Lambda de auth)

## Stack

| Item | Escolha |
|---|---|
| Nuvem | AWS (`sa-east-1` por padrão) |
| Kubernetes | EKS |
| Entrada | API Gateway HTTP API |
| IaC | Terraform ≥ 1.6 |
| Rede | VPC/subnets do remote state `db-infra` |

Repositórios irmãos: [core](https://github.com/fiap-pos-2026/tech-challenge-core) · [db-infra](https://github.com/fiap-pos-2026/tech-challenge-db-infra) · [auth-lambda](https://github.com/fiap-pos-2026/tech-challenge-auth-lambda)

```text
Internet
   │
   ▼
API Gateway ──► VPC Link / NLB ──► EKS (core)
   │
   └──► Lambda (auth CPF)  [tech-challenge-auth-lambda]
```

## Pré-requisitos

1. `tech-challenge-db-infra` já aplicado (VPC + RDS) com state remoto acessível.
2. Conta AWS + Terraform ≥ 1.6.
3. Bucket S3 + DynamoDB de lock (mesmo backend do db-infra, key diferente).

## Uso local

```bash
cp terraform.tfvars.example terraform.tfvars
cp backend.hcl.example backend.hcl
# edite bucket / tabela / region e o path do remote state do db-infra

terraform init -backend-config=backend.hcl
terraform plan -var-file=terraform.tfvars
terraform apply -var-file=terraform.tfvars
```

Atualizar kubeconfig:

```bash
aws eks update-kubeconfig --name <cluster_name> --region sa-east-1
kubectl get nodes
```

**Não commitar** `terraform.tfvars`, `backend.hcl` nem `*.tfstate`.

## CI/CD

Workflow em `.github/workflows/terraform.yml`: `fmt` / `validate` / `plan` em PR; `apply` em `main` (environment homolog).

Secrets: `AWS_ROLE_ARN`, `TF_STATE_BUCKET`, `TF_LOCK_TABLE`, e acesso de leitura ao state do `db-infra`.

## Custos

EKS control plane (~US$ 0,10/h), nodes EC2 e NAT (já no db-infra) consomem créditos. Use `terraform destroy` fora de demos e configure **AWS Budgets**.
