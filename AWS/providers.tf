terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
  
  # Variables are not allowed in the backend block
  backend "s3" {
    bucket         = "cloud-laptop-state-629b6a20" 
    key            = "cloud-laptop/terraform.tfstate"
    region         = "ap-northeast-1"
    dynamodb_table = "cloud-laptop-locks"
    encrypt        = true
  }
}

provider "aws" {
  region = var.aws_region
}
