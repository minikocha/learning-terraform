# nat-gateway

NATゲートウェイを作成し、`0.0.0.0/0`と`64:ff9b::/96`（NAT64）のルーティングを追加する。

<!-- BEGIN_TF_DOCS -->
## Providers

| Name | Version |
|------|---------|
| <a name="provider_awscc"></a> [awscc](#provider\_awscc) | 1.76.0 |

## Modules

No modules.

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_environment"></a> [environment](#input\_environment) | n/a | `string` | n/a | yes |
| <a name="input_project"></a> [project](#input\_project) | n/a | `string` | n/a | yes |
| <a name="input_route_table_id"></a> [route\_table\_id](#input\_route\_table\_id) | n/a | `string` | n/a | yes |
| <a name="input_short_region_code"></a> [short\_region\_code](#input\_short\_region\_code) | Abbreviated region code(e.g. ap-northeast-1 -> apne1) | `string` | n/a | yes |
| <a name="input_subnet_id"></a> [subnet\_id](#input\_subnet\_id) | n/a | `string` | n/a | yes |
| <a name="input_tags"></a> [tags](#input\_tags) | n/a | `list(object({ key = string, value = string }))` | n/a | yes |

## Outputs

No outputs.
<!-- END_TF_DOCS -->