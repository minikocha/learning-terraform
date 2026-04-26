locals {
  all_vars         = read_terragrunt_config(find_in_parent_folders("all.hcl"))
  environment_vars = read_terragrunt_config(find_in_parent_folders("environment.hcl"))
  region_vars      = read_terragrunt_config(find_in_parent_folders("region.hcl"))
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
  source = "${path_relative_from_include("root")}/modules/vpc"
}

dependency "log-store" {
  config_path = "../log-store"
  mock_outputs = {
    arn = "arn:aws:s3:::dummy-bucket"
  }
}

dependency "github-actions" {
  config_path = "../github-actions"
}

inputs = {
  cidr_block           = local.region_vars.locals.cidr_block
  environment          = local.environment_vars.locals.environment
  log_store_bucket_arn = dependency.log-store.outputs.arn
  project              = local.all_vars.locals.project
  short_region_code    = local.region_vars.locals.short_region_code
  tags = [
    { key = "Environment", value = local.environment_vars.locals.environment },
    { key = "Project", value = local.all_vars.locals.project },
    { key = "Terragrunt", value = path_relative_to_include("root") },
  ]
}
