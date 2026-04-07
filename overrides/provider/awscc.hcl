locals {
  region_vars = read_terragrunt_config(find_in_parent_folders("region.hcl"))
}

generate "provider_awscc" {
  path      = "provider_awscc_override.tf"
  if_exists = "overwrite_terragrunt"
  contents  = <<-EOF
    provider "awscc" {
      region = "${local.region_vars.locals.aws_region}"
    }
  EOF
}
