provider "aws" {
  region = "ap-south-1"
}

resource "aws_vpc" "devopscluster_vpc" {
  cidr_block = "10.0.0.0/16"

  tags = {
    Name = "devopscluster-vpc"
  }
}

resource "aws_subnet" "devopscluster_subnet" {
  count = 2
  vpc_id                  = aws_vpc.devopscluster_vpc.id
  cidr_block              = cidrsubnet(aws_vpc.devopscluster_vpc.cidr_block, 8, count.index)
  availability_zone       = element(["ap-south-1a", "ap-south-1b"], count.index)
  map_public_ip_on_launch = true

  tags = {
    Name = "devopscluster-subnet-${count.index}"
  }
}

resource "aws_internet_gateway" "devopscluster_igw" {
  vpc_id = aws_vpc.devopscluster_vpc.id

  tags = {
    Name = "devopscluster-igw"
  }
}

resource "aws_route_table" "devopscluster_route_table" {
  vpc_id = aws_vpc.devopscluster_vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.devopscluster_igw.id
  }

  tags = {
    Name = "devopscluster-route-table"
  }
}

resource "aws_route_table_association" "a" {
  count          = 2
  subnet_id      = aws_subnet.devopscluster_subnet[count.index].id
  route_table_id = aws_route_table.devopscluster_route_table.id
}

resource "aws_security_group" "devopscluster_cluster_sg" {
  vpc_id = aws_vpc.devopscluster_vpc.id

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "devopscluster-cluster-sg"
  }
}

resource "aws_security_group" "devopscluster_node_sg" {
  vpc_id = aws_vpc.devopscluster_vpc.id

  ingress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "devopscluster-node-sg"
  }
}

resource "aws_eks_cluster" "devopscluster" {
  name     = "devopscluster-cluster"
  role_arn = aws_iam_role.devopscluster_cluster_role.arn

  vpc_config {
    subnet_ids         = aws_subnet.devopscluster_subnet[*].id
    security_group_ids = [aws_security_group.devopscluster_cluster_sg.id]
  }
}

resource "aws_eks_node_group" "devopscluster" {
  cluster_name    = aws_eks_cluster.devopscluster.name
  node_group_name = "devopscluster-node-group"
  node_role_arn   = aws_iam_role.devopscluster_node_group_role.arn
  subnet_ids      = aws_subnet.devopscluster_subnet[*].id

  scaling_config {
    desired_size = 2
    max_size     = 2
    min_size     = 1
  }

  instance_types = ["t2.medium"]

  remote_access {
    ec2_ssh_key = var.ssh_key_name
    source_security_group_ids = [aws_security_group.devopscluster_node_sg.id]
  }
}

resource "aws_iam_role" "devopscluster_cluster_role" {
  name = "devopscluster-cluster-role"

  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Service": "eks.amazonaws.com"
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
EOF
}

resource "aws_iam_role_policy_attachment" "devopscluster_cluster_role_policy" {
  role       = aws_iam_role.devopscluster_cluster_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy"
}

resource "aws_iam_role" "devopscluster_node_group_role" {
  name = "devopscluster-node-group-role"

  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Service": "ec2.amazonaws.com"
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
EOF
}

resource "aws_iam_role_policy_attachment" "devopscluster_node_group_role_policy" {
  role       = aws_iam_role.devopscluster_node_group_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy"
}

resource "aws_iam_role_policy_attachment" "devopscluster_node_group_cni_policy" {
  role       = aws_iam_role.devopscluster_node_group_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy"
}

resource "aws_iam_role_policy_attachment" "devopscluster_node_group_registry_policy" {
  role       = aws_iam_role.devopscluster_node_group_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
}
