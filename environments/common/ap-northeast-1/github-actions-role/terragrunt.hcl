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
  source = "${path_relative_from_include("root")}/terraform/github-actions-role"
}

dependency "terraform-s3-backend" {
  config_path = "../terraform-s3-backend"
  mock_outputs = {
    bucket_name = "foo-bucket"
  }
}

inputs = {
  backend_bucket_name = dependency.terraform-s3-backend.outputs.bucket_name
  owner               = "minikocha"
  repository          = "learning-terraform"
  terragrunt_path     = path_relative_to_include("root")
}
