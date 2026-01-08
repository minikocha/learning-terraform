# github-actions-role

GitHub Actionsが使用するIAMロールを作成し、そのIAMロールのARNをGitHubのシークレットとして登録する。

## 事前準備

GitHub Appsを使用してGitHub Actionsでリソースを作成・更新する場合は、以下リンクを参照して事前にGitHub Appsを用意する。
https://qiita.com/nakamasato/items/077a72f2f06999d1d3bb

作成したGitHub Apps必要な権限は`Repository permissions`の以下。
- Contents: RW
- Environments: RW
- Metadata: RO
- Secrets: RW
- Variables: RW

<!-- BEGIN_TF_DOCS -->
## Providers

| Name | Version |
|------|---------|
| <a name="provider_aws"></a> [aws](#provider\_aws) | 6.27.0 |
| <a name="provider_awscc"></a> [awscc](#provider\_awscc) | 1.67.0 |
| <a name="provider_github"></a> [github](#provider\_github) | 6.9.0 |
| <a name="provider_tls"></a> [tls](#provider\_tls) | 4.1.0 |

## Modules

No modules.

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_backend_bucket_name"></a> [backend\_bucket\_name](#input\_backend\_bucket\_name) | terraformのバックエンドとして使用するS3バケット名 | `string` | n/a | yes |
| <a name="input_environment"></a> [environment](#input\_environment) | このリソースを使用する環境名 | `string` | n/a | yes |
| <a name="input_owner"></a> [owner](#input\_owner) | 対象となるGitHubリポジトリのオーナー名 | `string` | n/a | yes |
| <a name="input_project"></a> [project](#input\_project) | このリソースを使用するプロジェクト名 | `string` | n/a | yes |
| <a name="input_repository"></a> [repository](#input\_repository) | 対象となるGitHubリポジトリ名 | `string` | n/a | yes |
| <a name="input_terragrunt_path"></a> [terragrunt\_path](#input\_terragrunt\_path) | このリソースの作成を定義しているterragrunt.hclファイルのパス | `string` | n/a | yes |

## Outputs

No outputs.
<!-- END_TF_DOCS -->
