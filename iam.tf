# IAM Role for the EKS Cluster
resource "aws_iam_role" "eks_cluster_role" {
  name = "eks-cluster-role-devops"
  assume_role_policy = jsonencode({
    Statement = [{
      Action = "sts:AssumeRole"
      Effect = "Allow"
      Principal = {
        Service = "eks.amazonaws.com"
      }
    }]
    Version = "2012-10-17"
  })
  # This role allows the EKS control plane to manage AWS resources on your behalf.
}

# Permission Policies for the EKS Cluster
resource "aws_iam_role_policy_attachment" "eks_cluster_policy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy"
  role       = aws_iam_role.eks_cluster_role.name
  # Grants permissions required by the EKS control plane.
}
resource "aws_iam_role_policy_attachment" "eks_service_policy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSServicePolicy"
  role       = aws_iam_role.eks_cluster_role.name
  # Grants permissions required by the EKS service to interact with other AWS services.
}


# IAM Role for the Worker Nodes (EC2 Instances that run the containers)
resource "aws_iam_role" "eks_node_role" {
  name = "eks-node-role-devops"
  assume_role_policy = jsonencode({
    Statement = [{
      Action = "sts:AssumeRole"
      Effect = "Allow"
      Principal = {
        Service = "ec2.amazonaws.com"
      }
    }]
    Version = "2012-10-17"
  })
  # This role is assumed by the EC2 instances in the Node Group.
}

# Permission Policies for the Worker Nodes
resource "aws_iam_role_policy_attachment" "eks_node_worker_policy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy"
  role = aws_iam_role.eks_node_role.name
  # Allows worker nodes to connect to the EKS control plane.
}
resource "aws_iam_role_policy_attachment" "eks_node_cni_policy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy"
  role       = aws_iam_role.eks_node_role.name
  # Required for the Amazon VPC CNI plugin to manage network interfaces.
}
resource "aws_iam_role_policy_attachment" "eks_node_ecr_policy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
  role = aws_iam_role.eks_node_role.name
  # Grants read access to images stored in Amazon ECR.
}



