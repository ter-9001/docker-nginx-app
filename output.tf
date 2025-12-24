output "eks_cluster_name" {
  value = aws_eks_cluster.devops_cluster.name
}
output "eks_cluster_endpoint" {
  value = aws_eks_cluster.devops_cluster.endpoint
}
output "eks_cluster_version" {
  value = aws_eks_cluster.devops_cluster.version
}
