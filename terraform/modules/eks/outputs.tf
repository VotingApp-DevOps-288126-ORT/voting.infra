
output "cluster_name" {
  value = module.eks_cluster.name
}

output "cluster_endpoint" {
  value = module.eks_cluster.cluster_endpoint
}

output "cluster_certificate" {
  value = module.eks_cluster.cluster_certificate
}
