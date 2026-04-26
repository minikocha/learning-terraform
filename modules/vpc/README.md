# vpc

VPCと関連するリソースを作成する。

<!-- BEGIN_TF_DOCS -->
## Providers

| Name | Version |
| ---- | ------- |
| <a name="provider_aws"></a> [aws](#provider\_aws) | 6.42.0 |
| <a name="provider_awscc"></a> [awscc](#provider\_awscc) | 1.81.0 |

## Modules

No modules.

## Inputs

| Name | Description | Type | Default | Required |
| ---- | ----------- | ---- | ------- | :------: |
| <a name="input_cidr_block"></a> [cidr\_block](#input\_cidr\_block) | n/a | `string` | n/a | yes |
| <a name="input_environment"></a> [environment](#input\_environment) | n/a | `string` | n/a | yes |
| <a name="input_log_store_bucket_arn"></a> [log\_store\_bucket\_arn](#input\_log\_store\_bucket\_arn) | n/a | `string` | n/a | yes |
| <a name="input_project"></a> [project](#input\_project) | n/a | `string` | n/a | yes |
| <a name="input_short_region_code"></a> [short\_region\_code](#input\_short\_region\_code) | Abbreviated region code(e.g. ap-northeast-1 -> apne1) | `string` | n/a | yes |
| <a name="input_tags"></a> [tags](#input\_tags) | n/a | `list(object({ key = string, value = string }))` | n/a | yes |

## Outputs

| Name | Description |
| ---- | ----------- |
| <a name="output_elasticache_subnet_group_name"></a> [elasticache\_subnet\_group\_name](#output\_elasticache\_subnet\_group\_name) | n/a |
| <a name="output_private_subnet_cidr_blocks"></a> [private\_subnet\_cidr\_blocks](#output\_private\_subnet\_cidr\_blocks) | n/a |
| <a name="output_private_subnet_ids"></a> [private\_subnet\_ids](#output\_private\_subnet\_ids) | n/a |
| <a name="output_private_subnet_ipv6_cidr_blocks"></a> [private\_subnet\_ipv6\_cidr\_blocks](#output\_private\_subnet\_ipv6\_cidr\_blocks) | n/a |
| <a name="output_protected_subnet_cidr_blocks"></a> [protected\_subnet\_cidr\_blocks](#output\_protected\_subnet\_cidr\_blocks) | n/a |
| <a name="output_protected_subnet_ids"></a> [protected\_subnet\_ids](#output\_protected\_subnet\_ids) | n/a |
| <a name="output_protected_subnet_ipv6_cidr_blocks"></a> [protected\_subnet\_ipv6\_cidr\_blocks](#output\_protected\_subnet\_ipv6\_cidr\_blocks) | n/a |
| <a name="output_public_subnet_cidr_blocks"></a> [public\_subnet\_cidr\_blocks](#output\_public\_subnet\_cidr\_blocks) | n/a |
| <a name="output_public_subnet_ids"></a> [public\_subnet\_ids](#output\_public\_subnet\_ids) | n/a |
| <a name="output_public_subnet_ipv6_cidr_blocks"></a> [public\_subnet\_ipv6\_cidr\_blocks](#output\_public\_subnet\_ipv6\_cidr\_blocks) | n/a |
| <a name="output_rds_db_subnet_group_name"></a> [rds\_db\_subnet\_group\_name](#output\_rds\_db\_subnet\_group\_name) | n/a |
| <a name="output_vpc_cidr_block"></a> [vpc\_cidr\_block](#output\_vpc\_cidr\_block) | n/a |
| <a name="output_vpc_id"></a> [vpc\_id](#output\_vpc\_id) | n/a |
| <a name="output_vpc_ipv6_cidr_block"></a> [vpc\_ipv6\_cidr\_block](#output\_vpc\_ipv6\_cidr\_block) | n/a |
<!-- END_TF_DOCS -->