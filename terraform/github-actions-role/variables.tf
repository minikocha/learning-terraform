variable "backend_bucket_name" {
  type        = string
  description = "terraformのバックエンドとして使用するS3バケット名"
  nullable    = false
}

variable "environment" {
  type        = string
  description = "このリソースを使用する環境名"
  nullable    = false
}

variable "owner" {
  type        = string
  description = "対象となるGitHubリポジトリのオーナー名"
  nullable    = false
}

variable "project" {
  type        = string
  description = "このリソースを使用するプロジェクト名"
  nullable    = false
}

variable "repository" {
  type        = string
  description = "対象となるGitHubリポジトリ名"
  nullable    = false
}

variable "terragrunt_path" {
  type        = string
  description = "このリソースの作成を定義しているterragrunt.hclファイルのパス"
  nullable    = false
}
