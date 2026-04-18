output "vpc_cidr_block" {
  value = awscc_ec2_vpc.this.cidr_block
}

output "vpc_ipv6_cidr_block" {
  value = awscc_ec2_vpc_cidr_block.ipv6.ipv_6_cidr_block
}

output "vpc_id" {
  value = awscc_ec2_vpc.this.vpc_id
}

output "public_subnet_cidr_blocks" {
  value = [
    awscc_ec2_subnet.public_1.cidr_block,
    awscc_ec2_subnet.public_2.cidr_block,
  ]
}

output "public_subnet_ipv6_cidr_blocks" {
  value = [
    awscc_ec2_subnet.public_1.ipv_6_cidr_blocks[0],
    awscc_ec2_subnet.public_2.ipv_6_cidr_blocks[0],
  ]
}

output "public_subnet_ids" {
  value = [
    awscc_ec2_subnet.public_1.subnet_id,
    awscc_ec2_subnet.public_2.subnet_id,
  ]
}

output "public_subnet_route_table_id" {
  value = awscc_ec2_route_table.public.route_table_id
}

output "private_subnet_cidr_blocks" {
  value = [
    awscc_ec2_subnet.private_1.cidr_block,
    awscc_ec2_subnet.private_2.cidr_block,
  ]
}

output "private_subnet_ipv6_cidr_blocks" {
  value = [
    awscc_ec2_subnet.private_1.ipv_6_cidr_blocks[0],
    awscc_ec2_subnet.private_2.ipv_6_cidr_blocks[0],
  ]
}

output "private_subnet_ids" {
  value = [
    awscc_ec2_subnet.private_1.subnet_id,
    awscc_ec2_subnet.private_2.subnet_id,
  ]
}

output "private_subnet_route_table_id" {
  value = awscc_ec2_route_table.private.route_table_id
}

output "protected_subnet_cidr_blocks" {
  value = [
    awscc_ec2_subnet.protected_1.cidr_block,
    awscc_ec2_subnet.protected_2.cidr_block,
  ]
}

output "protected_subnet_ipv6_cidr_blocks" {
  value = [
    awscc_ec2_subnet.protected_1.ipv_6_cidr_blocks[0],
    awscc_ec2_subnet.protected_2.ipv_6_cidr_blocks[0],
  ]
}

output "protected_subnet_ids" {
  value = [
    awscc_ec2_subnet.protected_1.subnet_id,
    awscc_ec2_subnet.protected_2.subnet_id,
  ]
}

output "protected_subnet_route_table_id" {
  value = awscc_ec2_route_table.protected.route_table_id
}

output "elasticache_subnet_group_name" {
  value = awscc_elasticache_subnet_group.protected.cache_subnet_group_name
}

output "rds_db_subnet_group_name" {
  value = awscc_rds_db_subnet_group.protected.db_subnet_group_name
}
