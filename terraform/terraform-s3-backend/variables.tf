variable "environment" {
  type        = string
  description = "このリソースを使用する環境名"
  nullable    = false
}

variable "project" {
  type        = string
  description = "このリソースを使用するプロジェクト名"
  nullable    = false
}

variable "terragrunt_path" {
  type        = string
  description = "このリソースの作成を定義しているterragrunt.hclファイルのパス"
  nullable    = false
}
