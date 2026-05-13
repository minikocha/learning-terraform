output "cluster_name" {
  value = awscc_ecs_cluster.this.cluster_name
}

output "capacity_provider_name" {
  value = aws_ecs_capacity_provider.this.name
}
