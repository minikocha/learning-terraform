terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "6.44.0"
    }

    awscc = {
      source  = "hashicorp/awscc"
      version = "1.83.0"
    }

    github = {
      source  = "integrations/github"
      version = "6.12.1"
    }

    tls = {
      source  = "hashicorp/tls"
      version = "4.3.0"
    }
  }
}

provider "aws" {
  default_tags {
    tags = { for tag in var.tags : tag.key => tag.value }
  }
}

provider "github" {
  owner = "minikocha"
}
