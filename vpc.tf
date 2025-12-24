# Data to fetch Availability Zones (AZs)
data "aws_availability_zones" "available" {
  state = "available"
}

# EKS VPC Creation
resource "aws_vpc" "eks_vpc" {
  cidr_block             = "192.168.0.0/16" # New IP range, separate from your previous VPC
  enable_dns_support     = true
  enable_dns_hostnames = true
  tags = {
    Name = "EKS-VPC"
    # Essential tag for EKS and Load Balancers to function
    "kubernetes.io/cluster/eks-cluster-devops" = "owned"
  }
}

# Create Public Subnets for Load Balancers and access (in 2 different AZs)
resource "aws_subnet" "public_subnets" {
  count              = 2
  vpc_id             = aws_vpc.eks_vpc.id
  cidr_block         = cidrsubnet(aws_vpc.eks_vpc.cidr_block, 8, count.index)
  # map_public_ip_on_launch is mandatory for EKS/ALB public subnets
  map_public_ip_on_launch = true 
  availability_zone = data.aws_availability_zones.available.names[count.index]
  tags = {
    Name = "EKS-Public-Subnet-${count.index + 1}"
    # Tag required for the EKS Cluster
    "kubernetes.io/cluster/eks-cluster-devops" = "owned"
    # Tag required for the AWS Load Balancer Controller
    "kubernetes.io/role/elb" = 1 
  }
}

# Create Private Subnets for Worker Nodes (in 2 different AZs)
resource "aws_subnet" "private_subnets" {
  count              = 2
  vpc_id             = aws_vpc.eks_vpc.id
  # Subnet blocks that start after the public ones (indices 2 and 3)
  cidr_block         = cidrsubnet(aws_vpc.eks_vpc.cidr_block, 8, count.index + 2)
  availability_zone = data.aws_availability_zones.available.names[count.index]
  tags = {
    Name = "EKS-Private-Subnet-${count.index + 1}"
    "kubernetes.io/cluster/eks-cluster-devops" = "owned"
    # Tag required for the Worker Node Group
    "kubernetes.io/role/internal-elb" = 1 
  }
}

# Internet Gateway for public access (Load Balancers)
resource "aws_internet_gateway" "eks_gw" {
  vpc_id = aws_vpc.eks_vpc.id
  tags = {
    Name = "EKS-GW"
  }
}
# 1. Allocate an Elastic IP (EIP) for the NAT Gateway
resource "aws_eip" "nat_gateway_eip" {
  depends_on = [aws_internet_gateway.eks_gw] # Depends on the IGW
}

# 2. Create the NAT Gateway (in a Public Subnet)
resource "aws_nat_gateway" "eks_nat_gateway" {
  allocation_id = aws_eip.nat_gateway_eip.id
  # The NAT Gateway must be placed in ONE of the public subnets
  subnet_id       = aws_subnet.public_subnets[0].id 
  depends_on      = [aws_internet_gateway.eks_gw]

  tags = {
    Name = "EKS-NAT-GW"
  }
}

# 3. Create the Route Table for the Private Subnets
resource "aws_route_table" "private_route_table" {
  vpc_id = aws_vpc.eks_vpc.id
  tags = {
    Name = "EKS-Private-Route-Table"
  }
}

# 4. Add the outbound route (0.0.0.0/0) through the NAT Gateway
resource "aws_route" "private_internet_route" {
  route_table_id         = aws_route_table.private_route_table.id
  destination_cidr_block = "0.0.0.0/0"
  nat_gateway_id         = aws_nat_gateway.eks_nat_gateway.id
}

# 5. Associate the Route Table with the Private Subnets
# Association 1
resource "aws_route_table_association" "private_subnet_association_0" {
  subnet_id      = aws_subnet.private_subnets[0].id
  route_table_id = aws_route_table.private_route_table.id
}
# Association 2
resource "aws_route_table_association" "private_subnet_association_1" {
  subnet_id      = aws_subnet.private_subnets[1].id
  route_table_id = aws_route_table.private_route_table.id
}

# 6. Ensure Public Subnets use the IGW for the Internet
resource "aws_route_table" "public_route_table" {
  vpc_id = aws_vpc.eks_vpc.id
  tags = {
    Name = "EKS-Public-Route-Table"
  }
}


resource "aws_route" "public_internet_route" {
  route_table_id         = aws_route_table.public_route_table.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.eks_gw.id
}
resource "aws_route_table_association" "public_subnet_association_0" {
  subnet_id      = aws_subnet.public_subnets[0].id
  route_table_id = aws_route_table.public_route_table.id
}
resource "aws_route_table_association" "public_subnet_association_1" {
  subnet_id      = aws_subnet.public_subnets[1].id
  route_table_id = aws_route_table.public_route_table.id
}
