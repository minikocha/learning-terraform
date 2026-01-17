include "root" {
  path   = find_in_parent_folders("root.hcl")
  expose = true
}

include "provider_awscc" {
  path   = find_in_parent_folders("overrides/provider/awscc.hcl")
  expose = true
}

terraform {
  source = "${path_relative_from_include("root")}/terraform/terraform-s3-backend"
}

inputs = {
  terragrunt_path = path_relative_to_include("root")
}
