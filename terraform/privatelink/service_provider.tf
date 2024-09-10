provider "aws" {
  region = "us-east-1"
}

# Service provider VPC
resource "aws_vpc" "service_provider_vpc" {
  cidr_block = "10.1.0.0/16"
}

# Subnets for the service provider VPC
resource "aws_subnet" "service_provider_subnet" {
  count             = 2
  vpc_id            = aws_vpc.service_provider_vpc.id
  cidr_block        = cidrsubnet(aws_vpc.service_provider_vpc.cidr_block, 8, count.index)
  availability_zone = element(data.aws_availability_zones.available.names, count.index)
}

# Security group for the NLB
resource "aws_security_group" "service_provider_sg" {
  vpc_id = aws_vpc.service_provider_vpc.id

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

# Create an NLB for the service
resource "aws_lb" "service_nlb" {
  name               = "service-nlb"
  internal           = true
  load_balancer_type = "network"
  subnets            = aws_subnet.service_provider_subnet[*].id
}

# NLB Target Group
resource "aws_lb_target_group" "service_tg" {
  name     = "service-tg"
  port     = 80
  protocol = "TCP"
  vpc_id   = aws_vpc.service_provider_vpc.id
}

# NLB Listener
resource "aws_lb_listener" "service_listener" {
  load_balancer_arn = aws_lb.service_nlb.arn
  port              = 80
  protocol          = "TCP"
  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.service_tg.arn
  }
}

# Register targets for the NLB
resource "aws_instance" "service_instances" {
  count         = 2
  ami           = "ami-12345678" # Replace with a valid AMI ID
  instance_type = "t2.micro"
  subnet_id     = element(aws_subnet.service_provider_subnet[*].id, count.index)
  security_groups = [
    aws_security_group.service_provider_sg.id,
  ]

  tags = {
    Name = "ServiceInstance-${count.index}"
  }
}

resource "aws_lb_target_group_attachment" "service_tg_attachment" {
  count            = 2
  target_group_arn = aws_lb_target_group.service_tg.arn
  target_id        = aws_instance.service_instances[count.index].id
  port             = 80
}
