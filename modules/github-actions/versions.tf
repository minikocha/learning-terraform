terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "6.37.0"
    }

    awscc = {
      source  = "hashicorp/awscc"
      version = "1.76.0"
    }

    github = {
      source  = "integrations/github"
      version = "6.11.1"
    }

    tls = {
      source  = "hashicorp/tls"
      version = "4.2.1"
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
  owner = "minikocha"
}
