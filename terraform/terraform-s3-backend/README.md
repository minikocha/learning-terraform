# terraform-s3-backend

terraformのバックエンド用としてバージョニングとオブジェクトロックを有効化したS3バケットを作成する。

<!-- BEGIN_TF_DOCS -->
## Providers

| Name | Version |
|------|---------|
| <a name="provider_awscc"></a> [awscc](#provider\_awscc) | 1.67.0 |

## Modules

No modules.

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_environment"></a> [environment](#input\_environment) | このリソースを使用する環境名 | `string` | n/a | yes |
| <a name="input_project"></a> [project](#input\_project) | このリソースを使用するプロジェクト名 | `string` | n/a | yes |
| <a name="input_terragrunt_path"></a> [terragrunt\_path](#input\_terragrunt\_path) | このリソースの作成を定義しているterragrunt.hclファイルのパス | `string` | n/a | yes |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_bucket_name"></a> [bucket\_name](#output\_bucket\_name) | 作成されたS3バケット名 |
<!-- END_TF_DOCS -->
