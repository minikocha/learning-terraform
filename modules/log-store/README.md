# log-store

各種アクセスログを集約して保存するためのS3バケットを作成する。

<!-- BEGIN_TF_DOCS -->
## Providers

| Name | Version |
|------|---------|
| <a name="provider_aws"></a> [aws](#provider\_aws) | 6.37.0 |
| <a name="provider_awscc"></a> [awscc](#provider\_awscc) | 1.76.0 |

## Modules

No modules.

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_environment"></a> [environment](#input\_environment) | n/a | `string` | n/a | yes |
| <a name="input_project"></a> [project](#input\_project) | n/a | `string` | n/a | yes |
| <a name="input_tags"></a> [tags](#input\_tags) | n/a | `list(object({ key = string, value = string }))` | n/a | yes |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_arn"></a> [arn](#output\_arn) | n/a |
| <a name="output_bucket_name"></a> [bucket\_name](#output\_bucket\_name) | n/a |
<!-- END_TF_DOCS -->