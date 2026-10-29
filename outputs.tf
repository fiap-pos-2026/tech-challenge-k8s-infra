output "cluster_name" {
  description = "Nome do cluster EKS"
  value       = aws_eks_cluster.main.name
}

output "cluster_endpoint" {
  description = "Endpoint da API Kubernetes"
  value       = aws_eks_cluster.main.endpoint
}

output "cluster_certificate_authority_data" {
  description = "CA do cluster (base64)"
  value       = aws_eks_cluster.main.certificate_authority[0].data
  sensitive   = true
}

output "cluster_security_group_id" {
  description = "SG do control plane"
  value       = aws_security_group.eks_cluster.id
}

output "node_security_group_id" {
  description = "SG dos worker nodes"
  value       = aws_security_group.eks_nodes.id
}

output "oidc_provider_url" {
  description = "Issuer OIDC (IRSA)"
  value       = aws_eks_cluster.main.identity[0].oidc[0].issuer
}

output "api_gateway_id" {
  description = "ID da HTTP API"
  value       = aws_apigatewayv2_api.http.id
}

output "api_gateway_endpoint" {
  description = "URL pública do API Gateway"
  value       = aws_apigatewayv2_api.http.api_endpoint
}

output "configure_kubectl" {
  description = "Comando para configurar o kubeconfig"
  value       = "aws eks update-kubeconfig --name ${aws_eks_cluster.main.name} --region ${var.aws_region}"
}
