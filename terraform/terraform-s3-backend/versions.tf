terraform {
  required_providers {
    awscc = {
      source  = "hashicorp/awscc"
      version = "1.67.0"
    }
  }
}

provider "awscc" {
  region = "ap-northeast-1"
}
