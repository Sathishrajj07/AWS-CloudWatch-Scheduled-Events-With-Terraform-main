variable "region" {
  default = "us-east-1"
}

variable "availability_zone" {
  default = "us-east-1a"
}

variable "instance_type" {
  default = "t2.micro"
}

variable "ami" {
  // Amazon Linux 2 AMI (HVM), SSD Volume Type
  default = "ami-0323c3dd2da7fb37d"
}

variable "key_name" {
  default = "dev"
}

variable "name" {
  default = "ebs_snapshots"
}

variable "environment" {
  default = "dev"
}

variable "security_group_name" {
  default = "dev-sg"
}

variable "cron_expression" {
  default = "cron(0 13 * * ? *)"
}

variable "public_key_path" {
  default = "~/.ssh/id_rsa.pub"
}