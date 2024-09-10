provider "aws" {
  region = "us-east-1"
}

# Consumer VPC
resource "aws_vpc" "consumer_vpc" {
  cidr_block = "10.2.0.0/16"
}

# Subnets for the consumer VPC
resource "aws_subnet" "consumer_subnet" {
  count             = 2
  vpc_id            = aws_vpc.consumer_vpc.id
  cidr_block        = cidrsubnet(aws_vpc.consumer_vpc.cidr_block, 8, count.index)
  availability_zone = element(data.aws_availability_zones.available.names, count.index)
}

# Security group for instances in the consumer VPC
resource "aws_security_group" "consumer_sg" {
  vpc_id = aws_vpc.consumer_vpc.id

  ingress {
    protocol    = "tcp"
    from_port   = 80
    to_port     = 80
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    protocol    = "-1"
    from_port   = 0
    to_port     = 0
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# VPC Endpoint in the consumer VPC to connect to the service
resource "aws_vpc_endpoint" "private_link_endpoint" {
  vpc_id            = aws_vpc.consumer_vpc.id
  service_name      = aws_lb.service_nlb.arn # Reference NLB from the service provider's VPC
  vpc_endpoint_type = "Interface"
  subnet_ids        = aws_subnet.consumer_subnet[*].id
  security_group_ids = [
    aws_security_group.consumer_sg.id,
  ]
}

# Consumer EC2 instance to access the service
resource "aws_instance" "consumer_instance" {
  ami           = "ami-12345678" # Replace with a valid AMI ID
  instance_type = "t2.micro"
  subnet_id     = element(aws_subnet.consumer_subnet[*].id, 0)
  security_groups = [
    aws_security_group.consumer_sg.id,
  ]

  tags = {
    Name = "ConsumerInstance"
  }
}

