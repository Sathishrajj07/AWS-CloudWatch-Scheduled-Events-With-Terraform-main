terraform {
  required_version = ">= 0.12.24"
}

provider "aws" {
  version = "~> 2.30"
  profile = "default"
  region  = var.region
}

data "aws_vpc" "this" {
  default = true
}

data "aws_subnet" "subnet" {
  vpc_id            = data.aws_vpc.this.id
  availability_zone = var.availability_zone
}