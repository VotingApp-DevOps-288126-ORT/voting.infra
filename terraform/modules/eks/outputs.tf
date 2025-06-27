
output "cluster_name" {
  value = module.eks_cluster.name
}

output "cluster_endpoint" {
  value = module.eks_cluster.cluster_endpoint
}

output "cluster_certificate" {
  value = module.eks_cluster.cluster_certificate
}

output "cluster_auth" {
  value = data.aws_eks_cluster_auth.auth.token
}






