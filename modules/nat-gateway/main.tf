resource "awscc_ec2_eip" "this" {
  domain = "vpc"
  tags   = concat(var.tags, [{ key = "Name", value = "${var.project}-${var.environment}-${var.short_region_code}-nat" }, ])

  lifecycle {
    prevent_destroy = false # NOTE: IPアドレスを固定とする要件があれば`true`に変更する
  }
}

resource "awscc_ec2_nat_gateway" "this" {
  allocation_id              = awscc_ec2_eip.this.allocation_id
  availability_mode          = "zonal" # NOTE: 使用料金削減のため、冗長性は考慮しない
  connectivity_type          = "public"
  max_drain_duration_seconds = 1
  subnet_id                  = var.subnet_id
  tags                       = concat(var.tags, [{ key = "Name", value = "${var.project}-${var.environment}-${var.short_region_code}-nat" }, ])
}

resource "awscc_ec2_route" "ipv4_to_internet" {
  destination_cidr_block = "0.0.0.0/0"
  nat_gateway_id         = awscc_ec2_nat_gateway.this.nat_gateway_id
  route_table_id         = var.route_table_id
}

resource "awscc_ec2_route" "ipv6_to_nat64" {
  destination_ipv_6_cidr_block = "64:ff9b::/96"
  nat_gateway_id               = awscc_ec2_nat_gateway.this.nat_gateway_id
  route_table_id               = var.route_table_id
}
