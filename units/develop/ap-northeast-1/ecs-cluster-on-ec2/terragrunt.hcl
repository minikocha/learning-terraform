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
  source = "${path_relative_from_include("root")}/modules/ecs-cluster-on-ec2"
}

# NOTE: 2026/05/01時点でIPv6のみのVPCでのECS-Execはサポートされていないためコメントアウト
#dependency "log-store" {
#  config_path = "../log-store"
#  mock_outputs = {
#    bucket_name = "dummy"
#  }
#  mock_outputs_allowed_terraform_commands = ["plan", "validate", ]
#}

dependency "vpc" {
  config_path = "../vpc"
  mock_outputs = {
    private_subnet_ids = ["subnet-abcdefghijklmnopqr", ]
    vpc_id             = "vpc-abcdefghijklmnopq"
  }
  mock_outputs_allowed_terraform_commands = ["plan", "validate", ]
}

inputs = {
  capacity           = { default : 0, max : 1, min : 0, on_demand_base_capacity = 0, on_demand_percentage_above_base_capacity = 0 }
  container_insights = "disabled"
  environment        = local.environment_vars.locals.environment
  image_id           = "ami-07b6834a86f3632c8" # NOTE: arn:aws:ssm:ap-northeast-1::parameter/aws/service/ecs/optimized-ami/amazon-linux-2023/al2023-ami-ecs-hvm-2023.0.20260414-kernel-6.1-x86_64/image_id
  instance_types     = [{ instance_type : "t3.small", weighted_capacity : 1 }, ]
  project            = local.all_vars.locals.project
  short_region_code  = "apne1"
  subnet_ids         = dependency.vpc.outputs.private_subnet_ids
  tags = [
    { key = "Environment", value = local.environment_vars.locals.environment },
    { key = "Project", value = local.all_vars.locals.project },
    { key = "Terragrunt", value = path_relative_to_include("root") },
  ]
  vpc_id = dependency.vpc.outputs.vpc_id
}
