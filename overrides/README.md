# overrides

terragruntの設定ファイルからterraformの設定ファイル（プロバイダー設定など）を上書きするためのファイルを配置する。
[terraformの標準機能](https://developer.hashicorp.com/terraform/language/files/override)を使って上書きするため、ファイル名は`_override.tf`で終わらせる必要がある。

* 使用例
  ```
  include "provider_awscc" {
    path   = find_in_parent_folders("overrides/provider/awscc.hcl")
    expose = true
  }
  ```
