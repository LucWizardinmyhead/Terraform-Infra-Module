provider "aws" {
    region = var.aws_region
}

data "aws_ami" "amazon_linux" {
    most_recent = true
    owners = ["amazon"]

    filter {
      name = "name"
      values = ["amzn2-ami-hvm-*-x86_64-gp2"]
    }

    filter {
      name = "virtualization-type"
      values = ["hvm"]
    }
}

locals {
  my_ip = can(regex("^\\d+\\.\\d+\\.\\d+\\.\\d+$", chomp(data.http.my_public_ip.response_body))) ? "${chomp(data.http.my_public_ip.response_body)}/32" : null
}

resource "aws_vpc" "main" {
  cidr_block = "10.0.0.0/16"  # Adjust CIDR if needed
  tags = {
    Name = "prod-vpc"
  }
}

resource "aws_subnet" "public" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = "10.0.1.0/24"
  availability_zone       = "us-west-1a"
  map_public_ip_on_launch = true  # Critical for public access
  tags = {
    Name = "prod-public-subnet"
  }
}

resource "aws_security_group" "instance" {
    name = "ec2-sg"
    description = "Allows SSH from my IP and HTTP to everyone"
    vpc_id = aws_vpc.main.id
  
    ingress {
        from_port = 22
        to_port = 22
        protocol = "tcp"
        cidr_blocks = [local.my_ip]
    }

    ingress {
        from_port = 80
        to_port = 80
        protocol = "tcp"
        cidr_blocks = ["0.0.0.0/0"]
    }

    egress {
        from_port = 0
        to_port = 0
        protocol = "-1"
        cidr_blocks = ["0.0.0.0/0"]
    }
}

resource "aws_instance" "prod" {
  ami           = data.aws_ami.amazon_linux.id
  instance_type = "t2.micro"
  key_name      = "SSHkeypair"
  subnet_id     = aws_subnet.public.id
  vpc_security_group_ids = [aws_security_group.instance.id]

  tags = {
    Name = "prod-ec2"
    env = "prod"
  }

  lifecycle {
    create_before_destroy = true 
  }
}

resource "aws_internet_gateway" "gw" {
  vpc_id = aws_vpc.main.id
}

resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.gw.id
  }
}

resource "aws_route_table_association" "public" {
  subnet_id      = aws_subnet.public.id
  route_table_id = aws_route_table.public.id
}