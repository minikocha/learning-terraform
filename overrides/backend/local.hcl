remote_state {
  backend = "local"

  generate = {
    path      = "backend_override.tf"
    if_exists = "overwrite"
  }

  config = {
    path = "${get_terragrunt_dir()}/terraform.tfstate"
  }
}
