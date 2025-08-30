provider "aws" {
  region = "eu-south-1"
}

data "aws_ami" "amazon_linux" {
  most_recent = true
  owners      = ["071630900071"]

  filter {
    name   = "name"
    values = ["al2023-ami-2023.8.20250818.0-kernel-6.1-x86_64"]
  }

  filter {
    name   = "root-device-type"
    values = ["ebs"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

locals {
  all_subnets = concat(
    module.vpc1.private_subnets,
    module.vpc1.public_subnets,
    module.vpc2.private_subnets
  )
}

resource "aws_instance" "vpc1_istances" {
  count = length(concat(module.vpc1.private_subnets, module.vpc1.public_subnets))

  ami           = data.aws_ami.amazon_linux.id
  instance_type = var.instance_type
  subnet_id     = concat(module.vpc1.private_subnets, module.vpc1.public_subnets)[count.index]
  vpc_security_group_ids = [aws_security_group.vpc1_sg.id]
  key_name = aws_key_pair.pub_key.key_name
  associate_public_ip_address = contains(module.vpc1.public_subnets, concat(module.vpc1.private_subnets, module.vpc1.public_subnets)[count.index])

  tags = {
    Name = "${var.instance_name}-vpc1-${count.index + 1}"
  }
}

resource "aws_instance" "vpc2_istances" {
  count = length(module.vpc2.private_subnets)

  ami           = data.aws_ami.amazon_linux.id
  instance_type = var.instance_type
  subnet_id     = module.vpc2.private_subnets[count.index]
  vpc_security_group_ids = [aws_security_group.vpc2_sg.id]
  key_name = aws_key_pair.pub_key.key_name

  tags = {
    Name = "${var.instance_name}-vpc2-${count.index + 1}"
  }
}


module "vpc1" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "5.19.0"

  name = "vpc1"
  cidr = "10.10.0.0/16"

  azs             = ["eu-south-1a"]
  public_subnets  = ["10.10.1.0/24"]
  private_subnets = ["10.10.2.0/24"]

  enable_dns_hostnames    = true
  create_igw = true
}

module "vpc2" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "5.19.0"

  name = "vpc2"
  cidr = "20.20.0.0/16"

  azs             = ["eu-south-1a"]
  private_subnets = ["20.20.20.0/24"]

  enable_dns_hostnames    = true
}

resource "aws_vpc_peering_connection" "vpc1_vpc2" {
  vpc_id        = module.vpc1.vpc_id
  peer_vpc_id   = module.vpc2.vpc_id
  auto_accept   = true

  tags = {
    Name = "vpc1-vpc2-peering"
  }
}

resource "aws_route" "vpc1_to_vpc2" {
  route_table_id         = module.vpc1.private_route_table_ids[0]
  destination_cidr_block = module.vpc2.vpc_cidr_block
  vpc_peering_connection_id = aws_vpc_peering_connection.vpc1_vpc2.id
}

resource "aws_route" "vpc2_to_vpc1" {
  route_table_id         = module.vpc2.private_route_table_ids[0]
  destination_cidr_block = module.vpc1.vpc_cidr_block
  vpc_peering_connection_id = aws_vpc_peering_connection.vpc1_vpc2.id
}

resource "aws_security_group" "vpc1_sg" {
  name        = "vpc1_sg"
  description = "Security group for VPC1"
  vpc_id      = module.vpc1.vpc_id

  tags = {
    Name = "vpc1_sg"
  }
}

resource "aws_security_group" "vpc2_sg" {
  name        = "vpc2_sg"
  description = "Security group for VPC2"
  vpc_id      = module.vpc2.vpc_id

  tags = {
    Name = "vpc2_sg"
  }
}


resource "aws_vpc_security_group_ingress_rule" "ssh_rule_vpc1" {
  security_group_id = aws_security_group.vpc1_sg.id

  cidr_ipv4   = "0.0.0.0/0"
  from_port   = 22
  to_port     = 22
  ip_protocol = "tcp"
}

resource "aws_vpc_security_group_egress_rule" "all_vpc1" {
  security_group_id = aws_security_group.vpc1_sg.id

  cidr_ipv4   = "0.0.0.0/0"
  from_port   = 0
  to_port     = 0
  ip_protocol = "-1"
}

resource "aws_vpc_security_group_ingress_rule" "ssh_rule_vpc2" {
  security_group_id = aws_security_group.vpc2_sg.id

  cidr_ipv4   = "10.10.2.0/24"
  from_port   = 22
  to_port     = 22
  ip_protocol = "tcp"
}

resource "aws_key_pair" "pub_key" {
  key_name   = "aws-terraform-key"
  public_key = file("aws-terraform-key.pub")
 }

