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
  }
}

provider "aws" {
  region = "ap-northeast-1"

  default_tags {
    tags = { for tag in var.tags : tag.key => tag.value }
  }
}

provider "awscc" {
  region = "ap-northeast-1"
}
