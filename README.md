# tech-challenge-k8s-infra

Infraestrutura como código do **cluster Kubernetes** e da **entrada HTTP** da Fase 3 (The Java Garage).

Provisiona via **Terraform**:

- Cluster **Amazon EKS** (control plane + node group)
- Integração com a VPC do `tech-challenge-db-infra` (remote state)
- Security groups liberando tráfego dos nodes para o RDS (5432)
- Base de **API Gateway HTTP API** (rotas `/auth` e `/core` a preencher com Lambda/NLB)

## Stack

| Item | Escolha |
|---|---|
| Nuvem | AWS Academy Learner Lab (`us-east-1`) |
| Kubernetes | EKS |
| IAM (Academy) | Auto-detect `*LabEksClusterRole*` / `*LabEksNodeRole*` (prefixo do lab) — `voclabs` **não** cria IAM roles |
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

## Homolog — como obter outputs (sem expor no Git)

Repositórios **públicos** + lab efêmero: **não** versione endpoints de EKS/API Gateway, IDs de SG, nomes completos de IAM roles nem dados do RDS no README.

Após o `apply`:

```bash
terraform output
# principais: cluster_name, cluster_endpoint, api_gateway_endpoint,
# cluster_security_group_id, node_security_group_id,
# eks_cluster_role_name, eks_node_role_name, configure_kubectl
```

No Actions: job **Apply (homolog)** → log → `Outputs:`.

### kubectl (após ter o `cluster_name` no output)

```bash
aws eks update-kubeconfig --name "$(terraform output -raw cluster_name)" --region us-east-1
kubectl get nodes
```

RDS: outputs no state do [db-infra](https://github.com/fiap-pos-2026/tech-challenge-db-infra) (canal privado para JDBC/senha).

## Pré-requisitos

1. `tech-challenge-db-infra` já aplicado (VPC + RDS) com state remoto acessível.
2. Conta AWS + Terraform ≥ 1.6.
3. Bucket S3 + DynamoDB de lock (mesmo backend do db-infra, key `k8s-infra/homolog/terraform.tfstate`).
4. Lab Academy ativo; renovar secrets CLI a cada Start Lab.

## Uso local

```bash
cp terraform.tfvars.example terraform.tfvars
cp backend.hcl.example backend.hcl
# edite bucket / tabela / region e o path do remote state do db-infra

terraform init -backend-config=backend.hcl
terraform plan -var-file=terraform.tfvars
terraform apply -var-file=terraform.tfvars
```

**Não commitar** `terraform.tfvars`, `backend.hcl` nem `*.tfstate`.

## CI/CD

Workflow `.github/workflows/terraform.yml`: `fmt` / `validate` / `plan` em PR; `apply` em `main` (ou `workflow_dispatch` em `main`).

Secrets do repositório (só no GitHub Secrets): `AWS_ACCESS_KEY_ID`, `AWS_SECRET_ACCESS_KEY`, `AWS_SESSION_TOKEN`, `TF_STATE_BUCKET`, `TF_LOCK_TABLE`.

## Custos / budget

Maiores custos: **EKS control plane** + **nodes EC2** + NAT (no db-infra). Fora de demo, destruir **primeiro** este stack e depois o db-infra:

```bash
terraform destroy -var-file=terraform.tfvars   # neste repo
# depois destroy no tech-challenge-db-infra
```

Acompanhe o crédito no portal do Learner Lab. Detalhes no plano Fase 3 (seção budget).
