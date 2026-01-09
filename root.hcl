locals {
  all_vars         = read_terragrunt_config(find_in_parent_folders("all.hcl"))
  environment_vars = read_terragrunt_config(find_in_parent_folders("environment.hcl"))
  region_vars      = read_terragrunt_config(find_in_parent_folders("region.hcl"))
}

generate "override.tf" {
  path      = "override.tf"
  if_exists = "overwrite_terragrunt"
  contents  = <<-EOF
    terraform {
      required_version = ">= 1.14.2, < 2.0.0"
    }
  EOF
}

remote_state {
  backend = "s3"
  generate = {
    path      = "backend_s3.tf"
    if_exists = "overwrite_terragrunt"
  }
  config = {
    bucket       = "${local.all_vars.locals.state_backend_bucket}"
    key          = "${path_relative_to_include("root")}/terraform.tfstate"
    encrypt      = true
    region       = "${local.region_vars.locals.aws_region}"
    use_lockfile = true
  }
}

# NOTE: このファイルをincludeすると、インクルード元のinputsに3ファイルのローカル変数がマージされる
inputs = merge(
  local.all_vars.locals,
  local.environment_vars.locals,
  local.region_vars.locals,
)
