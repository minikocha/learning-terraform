terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "6.27.0"
    }

    awscc = {
      source  = "hashicorp/awscc"
      version = "1.67.0"
    }

    github = {
      source  = "integrations/github"
      version = "6.9.0"
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
