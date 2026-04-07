plugin "aws" {
  enabled = true
  source  = "github.com/terraform-linters/tflint-ruleset-aws"
  version = "0.45.0"
}

plugin "terraform" {
  enabled = true
  source  = "github.com/terraform-linters/tflint-ruleset-terraform"
  version = "0.14.1"
}

# --- ignore rules(terraform)
rule "terraform_documented_outputs" {
  enabled = false
}

rule "terraform_documented_variables" {
  enabled = false
}

rule "terraform_required_version" {
  enabled = false
}
