# ecs-cluster-on-ec2

ECSクラスター（ECS on EC2）を作成する。

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
| <a name="input_capacity"></a> [capacity](#input\_capacity) | n/a | <pre>object({<br/>    default                                  = number<br/>    max                                      = number<br/>    min                                      = number<br/>    on_demand_base_capacity                  = number<br/>    on_demand_percentage_above_base_capacity = number<br/>  })</pre> | n/a | yes |
| <a name="input_container_insights"></a> [container\_insights](#input\_container\_insights) | n/a | `string` | `"enabled"` | no |
| <a name="input_environment"></a> [environment](#input\_environment) | n/a | `string` | n/a | yes |
| <a name="input_image_id"></a> [image\_id](#input\_image\_id) | n/a | `string` | n/a | yes |
| <a name="input_instance_types"></a> [instance\_types](#input\_instance\_types) | n/a | `list(object({ instance_type = string, weighted_capacity = number }))` | n/a | yes |
| <a name="input_project"></a> [project](#input\_project) | n/a | `string` | n/a | yes |
| <a name="input_short_region_code"></a> [short\_region\_code](#input\_short\_region\_code) | Abbreviated region code(e.g. ap-northeast-1 -> apne1) | `string` | n/a | yes |
| <a name="input_subnet_ids"></a> [subnet\_ids](#input\_subnet\_ids) | n/a | `list(string)` | n/a | yes |
| <a name="input_tags"></a> [tags](#input\_tags) | n/a | `list(object({ key = string, value = string }))` | n/a | yes |
| <a name="input_vpc_id"></a> [vpc\_id](#input\_vpc\_id) | n/a | `string` | n/a | yes |

## Outputs

| Name | Description |
| ---- | ----------- |
| <a name="output_capacity_provider_name"></a> [capacity\_provider\_name](#output\_capacity\_provider\_name) | n/a |
| <a name="output_cluster_name"></a> [cluster\_name](#output\_cluster\_name) | n/a |
<!-- END_TF_DOCS -->