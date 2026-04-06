locals {
  all_vars         = read_terragrunt_config(find_in_parent_folders("all.hcl"))
  environment_vars = read_terragrunt_config(find_in_parent_folders("environment.hcl"))
}

include "root" {
  path   = find_in_parent_folders("root.hcl")
  expose = true
}

include "provider_aws" {
  path   = find_in_parent_folders("overrides/provider/aws.hcl")
  expose = true
}

include "provider_awscc" {
  path   = find_in_parent_folders("overrides/provider/awscc.hcl")
  expose = true
}

terraform {
  source = "${path_relative_from_include("root")}/modules/log-store"
}

inputs = {
  environment = local.environment_vars.locals.environment
  project     = local.all_vars.locals.project
  tags = [
    { key = "Environment", value = local.environment_vars.locals.environment },
    { key = "Project", value = local.all_vars.locals.project },
    { key = "Terragrunt", value = path_relative_to_include("root") },
  ]
}
