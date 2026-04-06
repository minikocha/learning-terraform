# github-actions

GitHub Actionsが使用するIAMロールを作成し、そのIAMロールのARNをGitHubのシークレットとして登録する。

## 事前準備

GitHub Appsを使用してGitHub Actionsでリソースを作成・更新する場合は、以下リンクを参照して事前にGitHub Appsを用意する。
https://qiita.com/nakamasato/items/077a72f2f06999d1d3bb

作成したGitHub Appsに必要な権限は`Repository permissions`の以下。
- Contents: `RW`
- Environments: `RW`
- Metadata: `RO`
- Secrets: `RW`
- Variables: `RW`

<!-- BEGIN_TF_DOCS -->
## Providers

| Name | Version |
|------|---------|
| <a name="provider_aws"></a> [aws](#provider\_aws) | 6.37.0 |
| <a name="provider_awscc"></a> [awscc](#provider\_awscc) | 1.76.0 |
| <a name="provider_github"></a> [github](#provider\_github) | 6.11.1 |
| <a name="provider_tls"></a> [tls](#provider\_tls) | 4.2.1 |

## Modules

No modules.

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_environment"></a> [environment](#input\_environment) | n/a | `string` | n/a | yes |
| <a name="input_log_store_bucket_name"></a> [log\_store\_bucket\_name](#input\_log\_store\_bucket\_name) | n/a | `string` | n/a | yes |
| <a name="input_project"></a> [project](#input\_project) | n/a | `string` | n/a | yes |
| <a name="input_tags"></a> [tags](#input\_tags) | n/a | `list(object({ key = string, value = string }))` | n/a | yes |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_state_store_bucket_name"></a> [state\_store\_bucket\_name](#output\_state\_store\_bucket\_name) | n/a |
<!-- END_TF_DOCS -->