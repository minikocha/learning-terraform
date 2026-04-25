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

## 権限の付与についての注意点

基本的には[checkov](https://github.com/bridgecrewio/checkov)（ないし、checkovが使用している[cloudsplaining](https://github.com/salesforce/cloudsplaining/blob/master/cloudsplaining/shared/constants.py)）の警告で気付ける可能性はあるが、権限の付与時に気をつけるべきアクションについて記載する。
以下のアクションの権限を付与する場合は、（可能な限り）`Resource`や`Condition`での制限について考慮する。

### 権限昇格

自身や他者に、それらが持つ権限よりも強い権限でのアクションの実行を許可する。

- `iam:AddUserToGroup`
- `iam:AttachGroupPolicy`
- `iam:AttachRolePolicy`
- `iam:AttachUserPolicy`
- `iam:CreatePolicyVersion`
- `iam:DeleteRolePermissionsBoundary`
- `iam:PassRole`
- `iam:PutGroupPolicy`
- `iam:PutRolePolicy`
- `iam:PutUserPolicy`
- `iam:UpdateAssumeRolePolicy`
- `sts:AssumeRole`

また、上記のアクションに`Resource`や`Condition`での制限を行っていたとしても、ワークロードの作成と実行の権限（`ec2:RunInstances`、`lambda:CreateFunction`と`lambda:InvokeFunction`など）と組み合わせることでも権限昇格が可能となることにも注意する。

### データ流出

機微な情報やクレデンシャルの全体または一部を取得する。

- `iam:CreateAccessKey`
- `iam:GetAccountEmailAddress`
- `iam:GetCloudFrontPublicKey`
- `iam:GetServerCertificate`
- `iam:GetSSHPublicKey`
- `iam:ListAccessKeys`
- `iam:UpdateAccessKey`
- `ec2:CopySnapshot`
- `ec2:GetPasswordData`
- `ec2:ModifySnapshotAttribute`
- `ecr:GetAuthorizationToken`
- `s3:GetObject`
- `ssm:GetParameter`
- `ssm:GetParameters`
- `ssm:GetParametersByPath`
- `secretsmanager:GetSecretValue`
- `ram:*`
- `rds:CopyDBSnapshot`
- `rds:ModifyDBSnapshotAttribute`

読み取りアクションだからといって安易に`Get*`と許可すると、広い範囲で権限を付与してしまうため注意する。

### AWSアカウント侵害

アカウントのセキュリティや統制を侵害する可能性がある。

- `organizations:*`
- `guardduty:*`
- `controltower:*`
- `cloudtrail:*`

そもそも該当アクションを許可しない。
許可する場合は最低限のアクションのみとし、OrganizationsのSCPやIAMのPermissions boundaryでの制限も同時に行う。

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
| <a name="output_read_policy_size"></a> [read\_policy\_size](#output\_read\_policy\_size) | n/a |
| <a name="output_state_store_bucket_name"></a> [state\_store\_bucket\_name](#output\_state\_store\_bucket\_name) | n/a |
| <a name="output_write_policy_size"></a> [write\_policy\_size](#output\_write\_policy\_size) | n/a |
<!-- END_TF_DOCS -->
