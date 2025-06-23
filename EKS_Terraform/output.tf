output "cluster_id" {
  value = aws_eks_cluster.devopscluster.id
}

output "node_group_id" {
  value = aws_eks_node_group.devopscluster.id
}

output "vpc_id" {
  value = aws_vpc.devopscluster_vpc.id
}

output "subnet_ids" {
  value = aws_subnet.devopscluster_subnet[*].id
}
