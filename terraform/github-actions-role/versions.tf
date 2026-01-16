terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "6.28.0"
    }

    awscc = {
      source  = "hashicorp/awscc"
      version = "1.68.0"
    }

    github = {
      source  = "integrations/github"
      version = "6.10.1"
    }

    tls = {
      source  = "hashicorp/tls"
      version = "4.1.0"
    }
  }
}

provider "aws" {
  region = "ap-northeast-1"
}

provider "awscc" {
  region = "ap-northeast-1"
}

provider "github" {
  owner = var.owner
}
