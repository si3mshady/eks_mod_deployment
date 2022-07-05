output "elliot_vpc_id" {
  value = aws_vpc.elliott-k8s-vpc.id
}

output "elliot_vpc_metadata" {
  value = aws_vpc.elliott-k8s-vpc
}

output "elliot_public_sg" {
  value = aws_security_group.public_sg
}


output "vpc_public_subnets" {
  value = aws_subnet.public_k8_subnets
}


output "vpc_private_subnets" {
  value = aws_subnet.private_k8_subnets
}
