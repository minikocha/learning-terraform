locals {
  environment_vars = read_terragrunt_config(find_in_parent_folders("environment.hcl"))
}

generate "override.tf" {
  path      = "override.tf"
  if_exists = "overwrite_terragrunt"
  contents  = <<-EOF
    terraform {
      required_version = ">= 1.15.3, < 2.0.0"
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
    bucket       = "${local.environment_vars.locals.state_store_bucket}"
    key          = "${path_relative_to_include("environment")}/terraform.tfstate"
    encrypt      = true
    region       = "ap-northeast-1"
    use_lockfile = true
  }
}

terraform {
  extra_arguments "plugin_cache" {
    commands = [
      "init",
      "plan",
      "apply",
      "destroy",
    ]

    env_vars = {
      TF_PLUGIN_CACHE_DIR = "${get_parent_terragrunt_dir()}/.terraform-plugin-cache"
    }
  }
}
