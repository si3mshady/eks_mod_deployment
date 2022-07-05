
provider "aws" {
  region     = "us-west-2"
  access_key = var.aws_access_key_id
  secret_key = var.aws_secret_access_key
}


terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
    
    }
  }
}


