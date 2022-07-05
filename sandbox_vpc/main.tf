
data "aws_availability_zones" "available" {}

resource "random_integer" "rand_int" {
  min = 1
  max = 10
}

resource "aws_vpc" "elliott-k8s-vpc" {
  cidr_block           = var.vpc_cidr
  enable_dns_hostnames = true
  enable_dns_support   = true
  tags = {
    Name = "elliott-k8s-${random_integer.rand_int.id}"
  }

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_subnet" "public_k8_subnets" {

  count = var.public_subnet_count

  cidr_block              = var.public_k8s_subnets[count.index]
  vpc_id                  = aws_vpc.elliott-k8s-vpc.id
  map_public_ip_on_launch = true
  availability_zone = data.aws_availability_zones.available.names[count.index]
  tags = {
    Name = "public-subnet-${count.index}"
  }
}


resource "aws_subnet" "private_k8_subnets" {

  count                   = var.private_subnet_count
  cidr_block              = var.private_k8s_subnets[count.index]
  vpc_id                  = aws_vpc.elliott-k8s-vpc.id
  map_public_ip_on_launch = true
  availability_zone = data.aws_availability_zones.available.names[count.index]

  tags = {
    Name = "private-subnet-${count.index}"
  }
}


resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.elliott-k8s-vpc.id
}


resource "aws_route_table" "public_route_table" {
  vpc_id = aws_vpc.elliott-k8s-vpc.id
  tags = {
    Name = "public_route_table"
  }
}


resource "aws_route_table_association" "public_rt_association" {
  count          = var.public_subnet_count
  subnet_id      = aws_subnet.public_k8_subnets.*.id[count.index]
  route_table_id = aws_route_table.public_route_table.id
}

resource "aws_route" "public_route" {
  route_table_id         = aws_route_table.public_route_table.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.igw.id
}



resource "aws_route_table" "private_route_table" {
  vpc_id = aws_vpc.elliott-k8s-vpc.id
  tags = {
    Name = "private_route_table"
  }
}


resource "aws_route" "private_route" {
  count          = var.private_subnet_count
  route_table_id         = aws_route_table.private_route_table.id
  destination_cidr_block = "0.0.0.0/0"

  gateway_id             = aws_internet_gateway.igw.id
}

resource "aws_route_table_association" "private_rt_association" {
  count          = var.private_subnet_count
  subnet_id      = aws_subnet.private_k8_subnets.*.id[count.index]
  route_table_id = aws_route_table.private_route_table.id
}





resource "aws_security_group" "public_sg" {

  name   = "public_sg"
  vpc_id = aws_vpc.elliott-k8s-vpc.id
  ingress {
    from_port   = 0
    to_port     = 65000
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    

  }
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}




resource "aws_security_group" "referenced_sg" {

  name   = "referenced_sg"
  vpc_id = aws_vpc.elliott-k8s-vpc.id
  ingress {
    from_port   = 0
    to_port     = 65000
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    security_groups = [aws_security_group.public_sg.id]

  }
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}




data "aws_ami" "ubuntu" {
  most_recent = true
}

resource "aws_key_pair" "elliot_public_key" {
  key_name   = "magnataur-public-key-"
  public_key = "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABgQCyhsApEqGuHOae0YTC90AK8a/Jx5PxUez0UoISKwLpb1625yq15D74Pu7jK0h2SFezZVIOYDnGMokeI0Lr4uj66/mj5T14YJx3wrx2DyvD9JSVSQsWtxngAFfWrfZsdaAR/q3zFILZzNXkRSsuPlw5jQilQzirKZ3Dq7USK5xU2jI6PBxFfp8kmWYhlUCD4w2Z7O/za43tdBUxwGQquTCGJxrzGuJcknwPIsnLgobSF1vkymqtEuvtBlNTAlzu99o0viZ4K9N57K3Qw7mKKjZNg/imboyEMtAyKDahjovF+TYvxArwonnCw38tuBVXBQGuOMsVW/a+YaagdOb9E1LlUf2G2yfwrDmdypsdJdQCq0OhFkbX3V6gHHcMPTfoTwAR+3jZlqTqBOy6vmu/VCg/AaTzG0HJDholsRo9ThY42ytlzQrJFKKeLueQDWzPS5zPV7zOrkbqGjZP00t6XbGnqGTdVCNtmPZrk2q+H4NYhlqMSrr08j/EDyIOncJOHP8="
}


resource "aws_instance" "web-bastion-public" {
  ami           = "ami-085284d24fe829cd0"
  instance_type = "t3.micro"
  associate_public_ip_address = true
  
  vpc_security_group_ids = [aws_security_group.public_sg.id, aws_security_group.referenced_sg.id]
  subnet_id = aws_subnet.public_k8_subnets[0].id
  key_name =  aws_key_pair.elliot_public_key.key_name
  tags = {
    Name = "Public-Bastion"
  }
}


resource "aws_instance" "web-bastion-private" {
  ami           = "ami-085284d24fe829cd0"
  instance_type = "t3.micro"
  associate_public_ip_address = false
  
  vpc_security_group_ids = [aws_security_group.public_sg.id, aws_security_group.referenced_sg.id]
  subnet_id = aws_subnet.private_k8_subnets[0].id
  key_name =  aws_key_pair.elliot_public_key.key_name
  tags = {
    Name = "Private-Instance"
  }
}


