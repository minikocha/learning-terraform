locals {
  all_vars         = read_terragrunt_config(find_in_parent_folders("all.hcl"))
  environment_vars = read_terragrunt_config(find_in_parent_folders("environment.hcl"))
  region_vars      = read_terragrunt_config(find_in_parent_folders("region.hcl"))
}

generate "provider_aws" {
  path      = "provider_aws_override.tf"
  if_exists = "overwrite_terragrunt"
  contents  = <<-EOF
    provider "aws" {
      region = "${local.region_vars.locals.aws_region}"

      default_tags {
        tags = { for tag in var.tags : tag.key => tag.value }
      }
    }
  EOF
}
