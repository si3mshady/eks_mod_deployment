variable "aws_access_key_id" {}
variable "aws_secret_access_key" {}

variable "vpc_cidr" {
  type    = string
  default = "10.40.0.0/16"
}


variable "aws_region" {
  type    = string
  default = "us-west-2"
}