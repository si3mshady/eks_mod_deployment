variable "aws_region" {
  type    = string
  default = "us-west-1"
}


variable "vpc_cidr" {
  type    = string
  default = "10.40.0.0/16"
}


variable "public_k8s_subnets" {
  type = list(any)
  # default = [for i in range(2, 255, 2) : cidrsubnet(var.vpc_cidr, 10, i)] #range = start end step 

}

variable "private_k8s_subnets" {
  type = list(any)
  # default = [for i in range(1, 255, 2) : cidrsubnet(var.vpc_cidr, 10, i)]

}


variable "public_subnet_count" {
  type = number
  default = 2

}

variable "private_subnet_count" {
  type = number
  default = 2

}