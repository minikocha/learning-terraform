data "aws_availability_zones" "available" {
  state = "available"
}

data "aws_region" "current" {}

resource "awscc_ec2_vpc" "this" {
  cidr_block           = var.cidr_block
  enable_dns_hostnames = true
  enable_dns_support   = true
  tags                 = concat(var.tags, [{ key = "Name", value = "${var.project}-${var.environment}-${var.short_region_code}" }])
}

resource "awscc_ec2_dhcp_options" "this" {
  domain_name_servers = ["AmazonProvidedDNS", ]
  tags                = concat(var.tags, [{ key = "Name", value = "${var.project}-${var.environment}-${var.short_region_code}" }])
}

resource "awscc_ec2_vpcdhcp_options_association" "this" {
  dhcp_options_id = awscc_ec2_dhcp_options.this.dhcp_options_id
  vpc_id          = awscc_ec2_vpc.this.vpc_id
}

resource "awscc_ec2_internet_gateway" "this" {
  tags = concat(var.tags, [{ key = "Name", value = "${var.project}-${var.environment}-${var.short_region_code}" }])
}

resource "awscc_ec2_vpc_gateway_attachment" "this" {
  internet_gateway_id = awscc_ec2_internet_gateway.this.internet_gateway_id
  vpc_id              = awscc_ec2_vpc.this.vpc_id
}

resource "awscc_ec2_egress_only_internet_gateway" "this" {
  vpc_id = awscc_ec2_vpc.this.vpc_id
}

resource "awscc_ec2_vpc_cidr_block" "ipv6" {
  amazon_provided_ipv_6_cidr_block = true
  vpc_id                           = awscc_ec2_vpc.this.vpc_id
}

resource "awscc_ec2_flow_log" "this" {
  destination_options = {
    file_format                = "plain-text"
    hive_compatible_partitions = true
    per_hour_partition         = true
  }
  log_destination      = "${var.log_store_bucket_arn}/vpc/"
  log_destination_type = "s3"
  resource_id          = awscc_ec2_vpc.this.vpc_id
  resource_type        = "VPC"
  tags                 = var.tags
  traffic_type         = "ALL"

  lifecycle {
    ignore_changes = [tags, ] # NOTE: タグの順番で差分を検知するため無視させる
  }
}

# IPアドレス設計IPv4)
#                   | AZ1[00]                           | AZ2[01]                           |
# | Public(0000)    | (0000)[00]00: 172.[16-31].0.0/22  | (0000)[01]00: 172.[16-31].4.0/22  |
# | Private(0001)   | (0001)[00]00: 172.[16-31].16.0/22 | (0001)[01]00: 172.[16-31].20.0/22 |
# | Protected(0010) | (0010)[00]00: 172.[16-31].32.0/22 | (0010)[01]00: 172.[16-31].36.0/22 |

# IPアドレス設計(IPv6)
#                   | AZ1[0000]                      | AZ2[0001]                      |
# | Public(0000)    | ...(0000)[0000]: ...:xx00::/64 | ...(0000)[0001]: ...:xx01::/64 |
# | Private(0001)   | ...(0001)[0000]: ...:xx10::/64 | ...(0001)[0001]: ...:xx11::/64 |
# | Protected(0010) | ...(0010)[0000]: ...:xx20::/64 | ...(0010)[0001]: ...:xx21::/64 |

# ----------------------------------------------------------------------------------------------------
# Public subnets and associated resources
# ----------------------------------------------------------------------------------------------------

resource "awscc_ec2_subnet" "public_1" {
  depends_on = [awscc_ec2_vpc_cidr_block.ipv6, ]

  assign_ipv_6_address_on_creation = true
  availability_zone                = data.aws_availability_zones.available.names[0]
  cidr_block                       = cidrsubnet(awscc_ec2_vpc.this.cidr_block, 6, 0)
  enable_dns_64                    = false # NOTE: 有効にする場合はNATゲートウェイを追加ののち、`64:ff9b::/96`をNATゲートウェイにルーティングする。
  ipv_6_cidr_block                 = cidrsubnet(awscc_ec2_vpc_cidr_block.ipv6.ipv_6_cidr_block, 8, 0)
  tags                             = concat(var.tags, [{ key = "Name", value = "${var.project}-${var.environment}-${var.short_region_code}-public-1" }])
  vpc_id                           = awscc_ec2_vpc.this.vpc_id

  lifecycle {
    ignore_changes = [tags, ] # NOTE: タグの順番で差分を検知するため無視させる
  }
}

resource "awscc_ec2_subnet" "public_2" {
  depends_on = [awscc_ec2_vpc_cidr_block.ipv6, ]

  assign_ipv_6_address_on_creation = true
  availability_zone                = data.aws_availability_zones.available.names[1]
  cidr_block                       = cidrsubnet(awscc_ec2_vpc.this.cidr_block, 6, 1)
  enable_dns_64                    = false # NOTE: 有効にする場合はNATゲートウェイを追加ののち、`64:ff9b::/96`をNATゲートウェイにルーティングする。
  ipv_6_cidr_block                 = cidrsubnet(awscc_ec2_vpc_cidr_block.ipv6.ipv_6_cidr_block, 8, 1)
  tags                             = concat(var.tags, [{ key = "Name", value = "${var.project}-${var.environment}-${var.short_region_code}-public-2" }])
  vpc_id                           = awscc_ec2_vpc.this.vpc_id

  lifecycle {
    ignore_changes = [tags, ] # NOTE: タグの順番で差分を検知するため無視させる
  }
}

resource "awscc_ec2_network_acl" "public" {
  tags   = concat(var.tags, [{ key = "Name", value = "${var.project}-${var.environment}-${var.short_region_code}-public" }])
  vpc_id = awscc_ec2_vpc.this.vpc_id
}

resource "awscc_ec2_subnet_network_acl_association" "public_1" {
  network_acl_id = awscc_ec2_network_acl.public.network_acl_id
  subnet_id      = awscc_ec2_subnet.public_1.subnet_id
}

resource "awscc_ec2_subnet_network_acl_association" "public_2" {
  network_acl_id = awscc_ec2_network_acl.public.network_acl_id
  subnet_id      = awscc_ec2_subnet.public_2.subnet_id
}

resource "awscc_ec2_route_table" "public" {
  tags   = concat(var.tags, [{ key = "Name", value = "${var.project}-${var.environment}-${var.short_region_code}-public" }])
  vpc_id = awscc_ec2_vpc.this.vpc_id
}

resource "awscc_ec2_subnet_route_table_association" "public_1" {
  route_table_id = awscc_ec2_route_table.public.route_table_id
  subnet_id      = awscc_ec2_subnet.public_1.subnet_id
}

resource "awscc_ec2_subnet_route_table_association" "public_2" {
  route_table_id = awscc_ec2_route_table.public.route_table_id
  subnet_id      = awscc_ec2_subnet.public_2.subnet_id
}

resource "awscc_ec2_route" "public_to_internet" {
  depends_on = [awscc_ec2_vpc_gateway_attachment.this, ]

  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = awscc_ec2_internet_gateway.this.internet_gateway_id
  route_table_id         = awscc_ec2_route_table.public.route_table_id
}

resource "awscc_ec2_route" "ipv6_public_to_internet" {
  depends_on = [awscc_ec2_vpc_gateway_attachment.this, ]

  destination_ipv_6_cidr_block = "::/0"
  gateway_id                   = awscc_ec2_internet_gateway.this.internet_gateway_id
  route_table_id               = awscc_ec2_route_table.public.route_table_id
}

# ----------------------------------------------------------------------------------------------------
# Private subnets and associated resources
# ----------------------------------------------------------------------------------------------------

resource "awscc_ec2_subnet" "private_1" {
  depends_on = [awscc_ec2_vpc_cidr_block.ipv6, ]

  assign_ipv_6_address_on_creation = true
  availability_zone                = data.aws_availability_zones.available.names[0]
  cidr_block                       = cidrsubnet(awscc_ec2_vpc.this.cidr_block, 6, 4)
  enable_dns_64                    = false # NOTE: 有効にする場合はNATゲートウェイを追加ののち、`64:ff9b::/96`をNATゲートウェイにルーティングする。
  ipv_6_cidr_block                 = cidrsubnet(awscc_ec2_vpc_cidr_block.ipv6.ipv_6_cidr_block, 8, 16)
  tags                             = concat(var.tags, [{ key = "Name", value = "${var.project}-${var.environment}-${var.short_region_code}-private-1" }])
  vpc_id                           = awscc_ec2_vpc.this.vpc_id

  lifecycle {
    ignore_changes = [tags, ] # NOTE: タグの順番で差分を検知するため無視させる
  }
}

resource "awscc_ec2_subnet" "private_2" {
  depends_on = [awscc_ec2_vpc_cidr_block.ipv6, ]

  assign_ipv_6_address_on_creation = true
  availability_zone                = data.aws_availability_zones.available.names[1]
  cidr_block                       = cidrsubnet(awscc_ec2_vpc.this.cidr_block, 6, 5)
  enable_dns_64                    = false # NOTE: 有効にする場合はNATゲートウェイを追加ののち、`64:ff9b::/96`をNATゲートウェイにルーティングする。
  ipv_6_cidr_block                 = cidrsubnet(awscc_ec2_vpc_cidr_block.ipv6.ipv_6_cidr_block, 8, 17)
  tags                             = concat(var.tags, [{ key = "Name", value = "${var.project}-${var.environment}-${var.short_region_code}-private-2" }])
  vpc_id                           = awscc_ec2_vpc.this.vpc_id

  lifecycle {
    ignore_changes = [tags, ] # NOTE: タグの順番で差分を検知するため無視させる
  }
}

resource "awscc_ec2_network_acl" "private" {
  tags   = concat(var.tags, [{ key = "Name", value = "${var.project}-${var.environment}-${var.short_region_code}-private" }])
  vpc_id = awscc_ec2_vpc.this.vpc_id
}

resource "awscc_ec2_subnet_network_acl_association" "private_1" {
  network_acl_id = awscc_ec2_network_acl.private.network_acl_id
  subnet_id      = awscc_ec2_subnet.private_1.subnet_id
}

resource "awscc_ec2_subnet_network_acl_association" "private_2" {
  network_acl_id = awscc_ec2_network_acl.private.network_acl_id
  subnet_id      = awscc_ec2_subnet.private_2.subnet_id
}

resource "awscc_ec2_route_table" "private" {
  tags   = concat(var.tags, [{ key = "Name", value = "${var.project}-${var.environment}-${var.short_region_code}-private" }])
  vpc_id = awscc_ec2_vpc.this.vpc_id
}

resource "awscc_ec2_subnet_route_table_association" "private_1" {
  route_table_id = awscc_ec2_route_table.private.route_table_id
  subnet_id      = awscc_ec2_subnet.private_1.subnet_id
}

resource "awscc_ec2_subnet_route_table_association" "private_2" {
  route_table_id = awscc_ec2_route_table.private.route_table_id
  subnet_id      = awscc_ec2_subnet.private_2.subnet_id
}

resource "awscc_ec2_route" "ipv6_private_to_internet" {
  destination_ipv_6_cidr_block    = "::/0"
  egress_only_internet_gateway_id = awscc_ec2_egress_only_internet_gateway.this.egress_only_internet_gateway_id
  route_table_id                  = awscc_ec2_route_table.private.route_table_id
}

# ----------------------------------------------------------------------------------------------------
# Protected subnets and associated resources
# ----------------------------------------------------------------------------------------------------

resource "awscc_ec2_subnet" "protected_1" {
  depends_on = [awscc_ec2_vpc_cidr_block.ipv6, ]

  assign_ipv_6_address_on_creation = true
  availability_zone                = data.aws_availability_zones.available.names[0]
  cidr_block                       = cidrsubnet(awscc_ec2_vpc.this.cidr_block, 6, 8)
  enable_dns_64                    = false # NOTE: 有効にする場合はNATゲートウェイを追加ののち、`64:ff9b::/96`をNATゲートウェイにルーティングする。
  ipv_6_cidr_block                 = cidrsubnet(awscc_ec2_vpc_cidr_block.ipv6.ipv_6_cidr_block, 8, 32)
  tags                             = concat(var.tags, [{ key = "Name", value = "${var.project}-${var.environment}-${var.short_region_code}-protected-1" }])
  vpc_id                           = awscc_ec2_vpc.this.vpc_id

  lifecycle {
    ignore_changes = [tags, ] # NOTE: タグの順番で差分を検知するため無視させる
  }
}

resource "awscc_ec2_subnet" "protected_2" {
  depends_on = [awscc_ec2_vpc_cidr_block.ipv6, ]

  assign_ipv_6_address_on_creation = true
  availability_zone                = data.aws_availability_zones.available.names[1]
  cidr_block                       = cidrsubnet(awscc_ec2_vpc.this.cidr_block, 6, 9)
  enable_dns_64                    = false # NOTE: 有効にする場合はNATゲートウェイを追加ののち、`64:ff9b::/96`をNATゲートウェイにルーティングする。
  ipv_6_cidr_block                 = cidrsubnet(awscc_ec2_vpc_cidr_block.ipv6.ipv_6_cidr_block, 8, 33)
  tags                             = concat(var.tags, [{ key = "Name", value = "${var.project}-${var.environment}-${var.short_region_code}-protected-2" }])
  vpc_id                           = awscc_ec2_vpc.this.vpc_id

  lifecycle {
    ignore_changes = [tags, ] # NOTE: タグの順番で差分を検知するため無視させる
  }
}

resource "awscc_ec2_network_acl" "protected" {
  tags   = concat(var.tags, [{ key = "Name", value = "${var.project}-${var.environment}-${var.short_region_code}-protected" }])
  vpc_id = awscc_ec2_vpc.this.vpc_id
}

resource "awscc_ec2_subnet_network_acl_association" "protected_1" {
  network_acl_id = awscc_ec2_network_acl.protected.network_acl_id
  subnet_id      = awscc_ec2_subnet.protected_1.subnet_id
}

resource "awscc_ec2_subnet_network_acl_association" "protected_2" {
  network_acl_id = awscc_ec2_network_acl.protected.network_acl_id
  subnet_id      = awscc_ec2_subnet.protected_2.subnet_id
}

resource "awscc_ec2_route_table" "protected" {
  tags   = concat(var.tags, [{ key = "Name", value = "${var.project}-${var.environment}-${var.short_region_code}-protected" }])
  vpc_id = awscc_ec2_vpc.this.vpc_id
}

resource "awscc_ec2_subnet_route_table_association" "protected_1" {
  route_table_id = awscc_ec2_route_table.protected.route_table_id
  subnet_id      = awscc_ec2_subnet.protected_1.subnet_id
}

resource "awscc_ec2_subnet_route_table_association" "protected_2" {
  route_table_id = awscc_ec2_route_table.protected.route_table_id
  subnet_id      = awscc_ec2_subnet.protected_2.subnet_id
}

# ネットワークACL設計
#
# - 共通事項
#   - 同一サブネットのAZ間通信は全てを許可する。
#   - ルール番号は以下のパターンに則って指定する。
#     - パターンA(1 - 5000)
#       絶対的なルールに使用
#     - パターンB(5001 - 10000)
#       IPアドレスとポート番号がそれぞれ個別に指定可能な許可ルール(例: `1.1.1.1:53`)に使用
#     - パターンC(10001 - 15000)
#       パターンDの例外用拒否ルールとして使用
#     - パターンD(15001 - 20000)
#       IPアドレスが個別で指定可能だがポート番号は範囲指定になるとき、またはIPアドレスがNWアドレス指定(`0.0.0.0/0`や`::0/0`は除く)の場合の許可ルールに使用
#     - パターンE(20001 - 25000)
#       パターンFの例外用拒否ルールとして使用
#     - パターンF(25001 - 30000)
#       IPアドレスが指定不可能(`0.0.0.0/0`や`::0/0`)な場合の許可ルールに使用
# - Public
#   - インターネット上のものと直接通信が行われるものを配置する。
#   - 同一VPC内においてはPrivateサブネットとのみ通信を許可する。
# - Private
#   - 間接的（LBやNAT越し）にインターネットに接続するものを配置する。
#     - ただし、IPv6においては直接通信を行う。
#   - 同一VPC内においてはPublic・Protectedとの通信を許可する。
# - Protected
#   - インターネットと通信する必要がないもの（RDSやElastiCacheなどのマネージドサービスを想定）を配置する。
#   - 同一VPC内においてはPrivateサブネットとのみ通信を許可する。

# ----------------------------------------------------------------------------------------------------
# Public subnet nacl entries(Egress)
# ----------------------------------------------------------------------------------------------------

resource "aws_network_acl_rule" "egress_public_to_public" {
  cidr_block     = cidrsubnet(awscc_ec2_vpc.this.cidr_block, 4, 0) # NOTE: 172.[16-31].0.0/20
  egress         = true
  network_acl_id = awscc_ec2_network_acl.public.network_acl_id
  protocol       = "-1"
  rule_action    = "allow"
  rule_number    = 101
}

resource "aws_network_acl_rule" "egress_ipv6_public_to_public" {
  egress          = true
  ipv6_cidr_block = cidrsubnet(awscc_ec2_vpc_cidr_block.ipv6.ipv_6_cidr_block, 4, 0) # NOTE: ...:xx00::/60
  network_acl_id  = awscc_ec2_network_acl.public.network_acl_id
  protocol        = "-1"
  rule_action     = "allow"
  rule_number     = 102
}

resource "aws_network_acl_rule" "egress_public_to_protected" {
  cidr_block     = cidrsubnet(awscc_ec2_vpc.this.cidr_block, 4, 2) # NOTE: 172.[16-31].32.0/20
  egress         = true
  network_acl_id = awscc_ec2_network_acl.public.network_acl_id
  protocol       = "-1"
  rule_action    = "deny"
  rule_number    = 201
}

resource "aws_network_acl_rule" "egress_ipv6_public_to_protected" {
  egress          = true
  ipv6_cidr_block = cidrsubnet(awscc_ec2_vpc_cidr_block.ipv6.ipv_6_cidr_block, 4, 2) # NOTE: ...:xx20::/60
  network_acl_id  = awscc_ec2_network_acl.public.network_acl_id
  protocol        = "-1"
  rule_action     = "deny"
  rule_number     = 202
}

resource "aws_network_acl_rule" "egress_public_to_private" {
  cidr_block     = cidrsubnet(awscc_ec2_vpc.this.cidr_block, 4, 1) # NOTE: 172.[16-31].16.0/20
  egress         = true
  network_acl_id = awscc_ec2_network_acl.public.network_acl_id
  protocol       = "-1"
  rule_action    = "allow"
  rule_number    = 15001
}

resource "aws_network_acl_rule" "egress_ipv6_public_to_private" {
  egress          = true
  ipv6_cidr_block = cidrsubnet(awscc_ec2_vpc_cidr_block.ipv6.ipv_6_cidr_block, 4, 1) # NOTE: ...:xx10::/60
  network_acl_id  = awscc_ec2_network_acl.public.network_acl_id
  protocol        = "-1"
  rule_action     = "allow"
  rule_number     = 15002
}

resource "aws_network_acl_rule" "egress_public_to_internet_tcp" {
  cidr_block     = "0.0.0.0/0"
  egress         = true
  from_port      = 0
  network_acl_id = awscc_ec2_network_acl.public.network_acl_id
  protocol       = "6"
  rule_action    = "allow"
  rule_number    = 25001
  to_port        = 65535
}

resource "aws_network_acl_rule" "egress_ipv6_public_to_internet_tcp" {
  egress          = true
  from_port       = 0
  ipv6_cidr_block = "::/0"
  network_acl_id  = awscc_ec2_network_acl.public.network_acl_id
  protocol        = "6"
  rule_action     = "allow"
  rule_number     = 25002
  to_port         = 65535
}

resource "aws_network_acl_rule" "egress_public_to_internet_udp" {
  cidr_block     = "0.0.0.0/0"
  egress         = true
  from_port      = 0
  network_acl_id = awscc_ec2_network_acl.public.network_acl_id
  protocol       = "17"
  rule_action    = "allow"
  rule_number    = 25003
  to_port        = 65535
}

resource "aws_network_acl_rule" "egress_ipv6_public_to_internet_udp" {
  egress          = true
  from_port       = 0
  ipv6_cidr_block = "::/0"
  network_acl_id  = awscc_ec2_network_acl.public.network_acl_id
  protocol        = "17"
  rule_action     = "allow"
  rule_number     = 25004
  to_port         = 65535
}

# ----------------------------------------------------------------------------------------------------
# Public subnet nacl entries(Ingress)
# ----------------------------------------------------------------------------------------------------

resource "aws_network_acl_rule" "ingress_public_from_public" {
  cidr_block     = cidrsubnet(awscc_ec2_vpc.this.cidr_block, 4, 0) # NOTE: 172.[16-31].0.0/20
  egress         = false
  network_acl_id = awscc_ec2_network_acl.public.network_acl_id
  protocol       = "-1"
  rule_action    = "allow"
  rule_number    = 101
}

resource "aws_network_acl_rule" "ingress_ipv6_public_from_public" {
  egress          = false
  ipv6_cidr_block = cidrsubnet(awscc_ec2_vpc_cidr_block.ipv6.ipv_6_cidr_block, 4, 0) # NOTE: ...:xx00::/60
  network_acl_id  = awscc_ec2_network_acl.public.network_acl_id
  protocol        = "-1"
  rule_action     = "allow"
  rule_number     = 102
}

resource "aws_network_acl_rule" "ingress_public_from_protected" {
  cidr_block     = cidrsubnet(awscc_ec2_vpc.this.cidr_block, 4, 2) # NOTE: 172.[16-31].32.0/20
  egress         = false
  network_acl_id = awscc_ec2_network_acl.public.network_acl_id
  protocol       = "-1"
  rule_action    = "deny"
  rule_number    = 201
}

resource "aws_network_acl_rule" "ingress_ipv6_public_from_protected" {
  egress          = false
  ipv6_cidr_block = cidrsubnet(awscc_ec2_vpc_cidr_block.ipv6.ipv_6_cidr_block, 4, 2) # NOTE: ...:xx20::/60
  network_acl_id  = awscc_ec2_network_acl.public.network_acl_id
  protocol        = "-1"
  rule_action     = "deny"
  rule_number     = 202
}

resource "aws_network_acl_rule" "ingress_public_from_private" {
  cidr_block     = cidrsubnet(awscc_ec2_vpc.this.cidr_block, 4, 1) # NOTE: 172.[16-31].16.0/20
  egress         = false
  network_acl_id = awscc_ec2_network_acl.public.network_acl_id
  protocol       = "-1"
  rule_action    = "allow"
  rule_number    = 15001
}

resource "aws_network_acl_rule" "ingress_ipv6_public_from_private" {
  egress          = false
  ipv6_cidr_block = cidrsubnet(awscc_ec2_vpc_cidr_block.ipv6.ipv_6_cidr_block, 4, 1) # NOTE: ...:xx10::/60
  network_acl_id  = awscc_ec2_network_acl.public.network_acl_id
  protocol        = "-1"
  rule_action     = "allow"
  rule_number     = 15002
}

resource "aws_network_acl_rule" "ingress_public_from_internet_ssh" {
  cidr_block     = "0.0.0.0/0"
  egress         = false
  from_port      = 22
  network_acl_id = awscc_ec2_network_acl.public.network_acl_id
  protocol       = "6"
  rule_action    = "deny"
  rule_number    = 20001
  to_port        = 22
}

resource "aws_network_acl_rule" "ingress_ipv6_public_from_internet_ssh" {
  egress          = false
  from_port       = 22
  ipv6_cidr_block = "::/0"
  network_acl_id  = awscc_ec2_network_acl.public.network_acl_id
  protocol        = "6"
  rule_action     = "deny"
  rule_number     = 20002
  to_port         = 22
}

resource "aws_network_acl_rule" "ingress_public_from_internet_rdp" {
  cidr_block     = "0.0.0.0/0"
  egress         = false
  from_port      = 3389
  network_acl_id = awscc_ec2_network_acl.public.network_acl_id
  protocol       = "6"
  rule_action    = "deny"
  rule_number    = 20003
  to_port        = 3389
}

resource "aws_network_acl_rule" "ingress_ipv6_public_from_internet_rdp" {
  egress          = false
  from_port       = 3389
  ipv6_cidr_block = "::/0"
  network_acl_id  = awscc_ec2_network_acl.public.network_acl_id
  protocol        = "6"
  rule_action     = "deny"
  rule_number     = 20004
  to_port         = 3389
}

resource "aws_network_acl_rule" "ingress_public_from_internet_tcp" {
  cidr_block     = "0.0.0.0/0"
  egress         = false
  from_port      = 0
  network_acl_id = awscc_ec2_network_acl.public.network_acl_id
  protocol       = "6"
  rule_action    = "allow"
  rule_number    = 25001
  to_port        = 65535
}

resource "aws_network_acl_rule" "ingress_ipv6_public_from_internet_tcp" {
  egress          = false
  from_port       = 0
  ipv6_cidr_block = "::/0"
  network_acl_id  = awscc_ec2_network_acl.public.network_acl_id
  protocol        = "6"
  rule_action     = "allow"
  rule_number     = 25002
  to_port         = 65535
}

resource "aws_network_acl_rule" "ingress_public_from_internet_udp" {
  cidr_block     = "0.0.0.0/0"
  egress         = false
  from_port      = 0
  network_acl_id = awscc_ec2_network_acl.public.network_acl_id
  protocol       = "17"
  rule_action    = "allow"
  rule_number    = 25003
  to_port        = 65535
}

resource "aws_network_acl_rule" "ingress_ipv6_public_from_internet_udp" {
  egress          = false
  from_port       = 0
  ipv6_cidr_block = "::/0"
  network_acl_id  = awscc_ec2_network_acl.public.network_acl_id
  protocol        = "17"
  rule_action     = "allow"
  rule_number     = 25004
  to_port         = 65535
}

# ----------------------------------------------------------------------------------------------------
# Private subnet nacl entries(Egress)
# ----------------------------------------------------------------------------------------------------

resource "aws_network_acl_rule" "egress_private_to_private" {
  cidr_block     = cidrsubnet(awscc_ec2_vpc.this.cidr_block, 4, 1) # NOTE: 172.[16-31].16.0/20
  egress         = true
  network_acl_id = awscc_ec2_network_acl.private.network_acl_id
  protocol       = "-1"
  rule_action    = "allow"
  rule_number    = 101
}

resource "aws_network_acl_rule" "egress_ipv6_private_to_private" {
  egress          = true
  ipv6_cidr_block = cidrsubnet(awscc_ec2_vpc_cidr_block.ipv6.ipv_6_cidr_block, 4, 1) # NOTE: ...:xx10::/60
  network_acl_id  = awscc_ec2_network_acl.private.network_acl_id
  protocol        = "-1"
  rule_action     = "allow"
  rule_number     = 102
}

resource "aws_network_acl_rule" "egress_private_to_public" {
  cidr_block     = cidrsubnet(awscc_ec2_vpc.this.cidr_block, 4, 0) # NOTE: 172.[16-31].0.0/20
  egress         = true
  network_acl_id = awscc_ec2_network_acl.private.network_acl_id
  protocol       = "-1"
  rule_action    = "allow"
  rule_number    = 15001
}

resource "aws_network_acl_rule" "egress_ipv6_private_to_public" {
  egress          = true
  ipv6_cidr_block = cidrsubnet(awscc_ec2_vpc_cidr_block.ipv6.ipv_6_cidr_block, 4, 0) # NOTE: ...:xx00::/60
  network_acl_id  = awscc_ec2_network_acl.private.network_acl_id
  protocol        = "-1"
  rule_action     = "allow"
  rule_number     = 15002
}

resource "aws_network_acl_rule" "egress_private_to_protected" {
  cidr_block     = cidrsubnet(awscc_ec2_vpc.this.cidr_block, 4, 2) # NOTE: 172.[16-31].32.0/20
  egress         = true
  network_acl_id = awscc_ec2_network_acl.private.network_acl_id
  protocol       = "-1"
  rule_action    = "allow"
  rule_number    = 15003
}

resource "aws_network_acl_rule" "egress_ipv6_private_to_protected" {
  egress          = true
  ipv6_cidr_block = cidrsubnet(awscc_ec2_vpc_cidr_block.ipv6.ipv_6_cidr_block, 4, 2) # NOTE: ...:xx20::/60
  network_acl_id  = awscc_ec2_network_acl.private.network_acl_id
  protocol        = "-1"
  rule_action     = "allow"
  rule_number     = 15004
}

resource "aws_network_acl_rule" "egress_private_to_internet_tcp" {
  cidr_block     = "0.0.0.0/0"
  egress         = true
  from_port      = 0
  network_acl_id = awscc_ec2_network_acl.private.network_acl_id
  protocol       = "6"
  rule_action    = "allow"
  rule_number    = 25001
  to_port        = 1023
}

resource "aws_network_acl_rule" "egress_ipv6_private_to_internet_tcp" {
  egress          = true
  from_port       = 0
  ipv6_cidr_block = "::/0"
  network_acl_id  = awscc_ec2_network_acl.private.network_acl_id
  protocol        = "6"
  rule_action     = "allow"
  rule_number     = 25002
  to_port         = 1023
}

resource "aws_network_acl_rule" "egress_private_to_internet_udp" {
  cidr_block     = "0.0.0.0/0"
  egress         = true
  from_port      = 0
  network_acl_id = awscc_ec2_network_acl.private.network_acl_id
  protocol       = "17"
  rule_action    = "allow"
  rule_number    = 25003
  to_port        = 1023
}

resource "aws_network_acl_rule" "egress_ipv6_private_to_internet_udp" {
  egress          = true
  from_port       = 0
  ipv6_cidr_block = "::/0"
  network_acl_id  = awscc_ec2_network_acl.private.network_acl_id
  protocol        = "17"
  rule_action     = "allow"
  rule_number     = 25004
  to_port         = 1023
}

# ----------------------------------------------------------------------------------------------------
# Private subnet nacl entries(Ingress)
# ----------------------------------------------------------------------------------------------------

resource "aws_network_acl_rule" "ingress_private_from_private" {
  cidr_block     = cidrsubnet(awscc_ec2_vpc.this.cidr_block, 4, 1) # NOTE: 172.[16-31].16.0/20
  egress         = false
  network_acl_id = awscc_ec2_network_acl.private.network_acl_id
  protocol       = "-1"
  rule_action    = "allow"
  rule_number    = 101
}

resource "aws_network_acl_rule" "ingress_ipv6_private_from_private" {
  egress          = false
  ipv6_cidr_block = cidrsubnet(awscc_ec2_vpc_cidr_block.ipv6.ipv_6_cidr_block, 4, 1) # NOTE: ...:xx10::/60
  network_acl_id  = awscc_ec2_network_acl.private.network_acl_id
  protocol        = "-1"
  rule_action     = "allow"
  rule_number     = 102
}

resource "aws_network_acl_rule" "ingress_private_from_public" {
  cidr_block     = cidrsubnet(awscc_ec2_vpc.this.cidr_block, 4, 0) # NOTE: 172.[16-31].0.0/20
  egress         = false
  network_acl_id = awscc_ec2_network_acl.private.network_acl_id
  protocol       = "-1"
  rule_action    = "allow"
  rule_number    = 15001
}

resource "aws_network_acl_rule" "ingress_ipv6_private_from_public" {
  egress          = false
  ipv6_cidr_block = cidrsubnet(awscc_ec2_vpc_cidr_block.ipv6.ipv_6_cidr_block, 4, 0) # NOTE: ...:xx00::/60
  network_acl_id  = awscc_ec2_network_acl.private.network_acl_id
  protocol        = "-1"
  rule_action     = "allow"
  rule_number     = 15002
}

resource "aws_network_acl_rule" "ingress_private_from_protected" {
  cidr_block     = cidrsubnet(awscc_ec2_vpc.this.cidr_block, 4, 2) # NOTE: 172.[16-31].32.0/20
  egress         = false
  network_acl_id = awscc_ec2_network_acl.private.network_acl_id
  protocol       = "-1"
  rule_action    = "allow"
  rule_number    = 15003
}

resource "aws_network_acl_rule" "ingress_ipv6_private_from_protected" {
  egress          = false
  ipv6_cidr_block = cidrsubnet(awscc_ec2_vpc_cidr_block.ipv6.ipv_6_cidr_block, 4, 2) # NOTE: ...:xx20::/60
  network_acl_id  = awscc_ec2_network_acl.private.network_acl_id
  protocol        = "-1"
  rule_action     = "allow"
  rule_number     = 15004
}

resource "aws_network_acl_rule" "ingress_private_from_internet_tcp" {
  cidr_block     = "0.0.0.0/0"
  egress         = false
  from_port      = 1024
  network_acl_id = awscc_ec2_network_acl.private.network_acl_id
  protocol       = "6"
  rule_action    = "allow"
  rule_number    = 25001
  to_port        = 65535
}

resource "aws_network_acl_rule" "ingress_ipv6_private_from_internet_tcp" {
  egress          = false
  from_port       = 1024
  ipv6_cidr_block = "::/0"
  network_acl_id  = awscc_ec2_network_acl.private.network_acl_id
  protocol        = "6"
  rule_action     = "allow"
  rule_number     = 25002
  to_port         = 65535
}

resource "aws_network_acl_rule" "ingress_private_from_internet_udp" {
  cidr_block     = "0.0.0.0/0"
  egress         = false
  from_port      = 1024
  network_acl_id = awscc_ec2_network_acl.private.network_acl_id
  protocol       = "17"
  rule_action    = "allow"
  rule_number    = 25003
  to_port        = 65535
}

resource "aws_network_acl_rule" "ingress_ipv6_private_from_internet_udp" {
  egress          = false
  from_port       = 1024
  ipv6_cidr_block = "::/0"
  network_acl_id  = awscc_ec2_network_acl.private.network_acl_id
  protocol        = "17"
  rule_action     = "allow"
  rule_number     = 25004
  to_port         = 65535
}

# ----------------------------------------------------------------------------------------------------
# Protected subnet nacl entries(Egress)
# ----------------------------------------------------------------------------------------------------

resource "aws_network_acl_rule" "egress_protected_to_protected" {
  cidr_block     = cidrsubnet(awscc_ec2_vpc.this.cidr_block, 4, 2) # NOTE: 172.[16-31].32.0/20
  egress         = true
  network_acl_id = awscc_ec2_network_acl.protected.network_acl_id
  protocol       = "-1"
  rule_action    = "allow"
  rule_number    = 101
}

resource "aws_network_acl_rule" "egress_ipv6_protected_to_protected" {
  egress          = true
  ipv6_cidr_block = cidrsubnet(awscc_ec2_vpc_cidr_block.ipv6.ipv_6_cidr_block, 4, 2) # NOTE: ...:xx20::/60
  network_acl_id  = awscc_ec2_network_acl.protected.network_acl_id
  protocol        = "-1"
  rule_action     = "allow"
  rule_number     = 102
}

resource "aws_network_acl_rule" "egress_protected_to_public" {
  cidr_block     = cidrsubnet(awscc_ec2_vpc.this.cidr_block, 4, 0) # NOTE: 172.[16-31].0.0/20
  egress         = true
  network_acl_id = awscc_ec2_network_acl.protected.network_acl_id
  protocol       = "-1"
  rule_action    = "deny"
  rule_number    = 201
}

resource "aws_network_acl_rule" "egress_ipv6_protected_to_public" {
  egress          = true
  ipv6_cidr_block = cidrsubnet(awscc_ec2_vpc_cidr_block.ipv6.ipv_6_cidr_block, 4, 0) # NOTE: ...:xx00::/60
  network_acl_id  = awscc_ec2_network_acl.protected.network_acl_id
  protocol        = "-1"
  rule_action     = "deny"
  rule_number     = 202
}

resource "aws_network_acl_rule" "egress_protected_to_private" {
  cidr_block     = cidrsubnet(awscc_ec2_vpc.this.cidr_block, 4, 1) # NOTE: 172.[16-31].16.0/20
  egress         = true
  network_acl_id = awscc_ec2_network_acl.protected.network_acl_id
  protocol       = "-1"
  rule_action    = "allow"
  rule_number    = 15001
}

resource "aws_network_acl_rule" "egress_ipv6_protected_to_private" {
  egress          = true
  ipv6_cidr_block = cidrsubnet(awscc_ec2_vpc_cidr_block.ipv6.ipv_6_cidr_block, 4, 1) # NOTE: ...:xx10::/60
  network_acl_id  = awscc_ec2_network_acl.protected.network_acl_id
  protocol        = "-1"
  rule_action     = "allow"
  rule_number     = 15002
}

# ----------------------------------------------------------------------------------------------------
# Protected subnet nacl entries(Ingress)
# ----------------------------------------------------------------------------------------------------

resource "aws_network_acl_rule" "ingress_protected_from_protected" {
  cidr_block     = cidrsubnet(awscc_ec2_vpc.this.cidr_block, 4, 2) # NOTE: 172.[16-31].32.0/20
  egress         = false
  network_acl_id = awscc_ec2_network_acl.protected.network_acl_id
  protocol       = "-1"
  rule_action    = "allow"
  rule_number    = 101
}

resource "aws_network_acl_rule" "ingress_ipv6_protected_from_protected" {
  egress          = false
  ipv6_cidr_block = cidrsubnet(awscc_ec2_vpc_cidr_block.ipv6.ipv_6_cidr_block, 4, 2) # NOTE: ...:xx20::/60
  network_acl_id  = awscc_ec2_network_acl.protected.network_acl_id
  protocol        = "-1"
  rule_action     = "allow"
  rule_number     = 102
}

resource "aws_network_acl_rule" "ingress_protected_from_public" {
  cidr_block     = cidrsubnet(awscc_ec2_vpc.this.cidr_block, 4, 0) # NOTE: 172.[16-31].0.0/20
  egress         = false
  network_acl_id = awscc_ec2_network_acl.protected.network_acl_id
  protocol       = "-1"
  rule_action    = "deny"
  rule_number    = 201
}

resource "aws_network_acl_rule" "ingress_ipv6_protected_from_public" {
  egress          = false
  ipv6_cidr_block = cidrsubnet(awscc_ec2_vpc_cidr_block.ipv6.ipv_6_cidr_block, 4, 0) # NOTE: ...:xx00::/60
  network_acl_id  = awscc_ec2_network_acl.protected.network_acl_id
  protocol        = "-1"
  rule_action     = "deny"
  rule_number     = 202
}

resource "aws_network_acl_rule" "ingress_protected_from_private" {
  cidr_block     = cidrsubnet(awscc_ec2_vpc.this.cidr_block, 4, 1) # NOTE: 172.[16-31].16.0/20
  egress         = false
  network_acl_id = awscc_ec2_network_acl.protected.network_acl_id
  protocol       = "-1"
  rule_action    = "allow"
  rule_number    = 15001
}

resource "aws_network_acl_rule" "ingress_ipv6_protected_from_private" {
  egress          = false
  ipv6_cidr_block = cidrsubnet(awscc_ec2_vpc_cidr_block.ipv6.ipv_6_cidr_block, 4, 1) # NOTE: ...:xx10::/60
  network_acl_id  = awscc_ec2_network_acl.protected.network_acl_id
  protocol        = "-1"
  rule_action     = "allow"
  rule_number     = 15002
}

# ----------------------------------------------------------------------------------------------------
# Gateway type vpc endpoints
# ----------------------------------------------------------------------------------------------------

resource "awscc_ec2_vpc_endpoint" "dynamodb" {
  route_table_ids   = [awscc_ec2_route_table.private.route_table_id, ]
  service_name      = "com.amazonaws.${data.aws_region.current.id}.dynamodb"
  tags              = concat(var.tags, [{ key = "Name", value = "${var.project}-${var.environment}-${var.short_region_code}-dynamodb" }])
  vpc_endpoint_type = "Gateway"
  vpc_id            = awscc_ec2_vpc.this.vpc_id
}

resource "awscc_ec2_vpc_endpoint" "s3" {
  route_table_ids   = [awscc_ec2_route_table.private.route_table_id, ]
  service_name      = "com.amazonaws.${data.aws_region.current.id}.s3"
  tags              = concat(var.tags, [{ key = "Name", value = "${var.project}-${var.environment}-${var.short_region_code}-s3" }])
  vpc_endpoint_type = "Gateway"
  vpc_id            = awscc_ec2_vpc.this.vpc_id
}

# ----------------------------------------------------------------------------------------------------
# Subnet groups
# ----------------------------------------------------------------------------------------------------

resource "awscc_elasticache_subnet_group" "protected" {
  cache_subnet_group_name = "${var.project}-${var.environment}-${var.short_region_code}-protected"
  description             = "in protected subnets"
  subnet_ids = [
    awscc_ec2_subnet.protected_1.subnet_id,
    awscc_ec2_subnet.protected_2.subnet_id,
  ]
  tags = var.tags
}

resource "awscc_rds_db_subnet_group" "protected" {
  db_subnet_group_description = "in protected subnets"
  db_subnet_group_name        = "${var.project}-${var.environment}-${var.short_region_code}-protected"
  subnet_ids = [
    awscc_ec2_subnet.protected_1.subnet_id,
    awscc_ec2_subnet.protected_2.subnet_id,
  ]
  tags = var.tags
}
