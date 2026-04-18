locals {
  all_vars         = read_terragrunt_config(find_in_parent_folders("all.hcl"))
  environment_vars = read_terragrunt_config(find_in_parent_folders("environment.hcl"))
  region_vars      = read_terragrunt_config(find_in_parent_folders("region.hcl"))
}

include "root" {
  path   = find_in_parent_folders("root.hcl")
  expose = true
}

include "provider_awscc" {
  path   = find_in_parent_folders("overrides/provider/awscc.hcl")
  expose = true
}

terraform {
  source = "${path_relative_from_include("root")}/modules/nat-gateway"
}

dependency "vpc" {
  config_path = "../vpc"
  mock_outputs = {
    private_subnet_route_table_id = "rtb-0123456789abcdefg"
    public_subnet_ids             = ["subnet-01234567890abcdef", ]
  }
}

inputs = {
  environment       = local.environment_vars.locals.environment
  project           = local.all_vars.locals.project
  route_table_id    = dependency.vpc.outputs.private_subnet_route_table_id
  short_region_code = local.region_vars.locals.short_region_code
  subnet_id         = dependency.vpc.outputs.public_subnet_ids[0]
  tags = [
    { key = "Environment", value = local.environment_vars.locals.environment },
    { key = "Project", value = local.all_vars.locals.project },
    { key = "Terragrunt", value = path_relative_to_include("root") },
  ]
}
