# EKS Cluster Creation
resource "aws_eks_cluster" "devops_cluster" {
  name     = "eks-cluster-devops"
  role_arn = aws_iam_role.eks_cluster_role.arn
  version  = "1.29" # Stable Kubernetes version
  
  vpc_config {
    subnet_ids = concat(aws_subnet.public_subnets[*].id, aws_subnet.private_subnets[*].id)
    # Allows the Kubernetes API server to be accessed publicly
    endpoint_public_access = true 
  }
}

# Node Group (where EC2/workers run)
resource "aws_eks_node_group" "private_node_group" {
  cluster_name    = aws_eks_cluster.devops_cluster.name
  node_group_name = "private-workers"
  # Places Worker Nodes only in private subnets
  subnet_ids      = aws_subnet.private_subnets[*].id 
  node_role_arn   = aws_iam_role.eks_node_role.arn
  instance_types  = ["t2.small"]

  # Autoscaling Configuration
  scaling_config {
    desired_size = 2 # Start with 2 instances
    max_size     = 3
    min_size     = 1
  }

  # Tag Configuration for Worker Nodes (optional, but good practice)
  tags = {
    Name = "EKS-Worker-Node-Group"
  }

  # Important: waits for the cluster to be active before attempting to attach the nodes
  depends_on = [
    aws_iam_role_policy_attachment.eks_node_worker_policy,
    aws_iam_role_policy_attachment.eks_node_cni_policy,
    aws_iam_role_policy_attachment.eks_node_ecr_policy,
  ]
}
