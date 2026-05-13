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
  }
}

provider "aws" {
  default_tags {
    tags = { for tag in var.tags : tag.key => tag.value }
  }
}
