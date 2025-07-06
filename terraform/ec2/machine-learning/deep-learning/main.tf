# Get default VPC
data "aws_vpc" "default" {
  default = true
}

# Get a default subnet from the default VPC
# data "aws_subnet_ids" "default" {
#   vpc_id = data.aws_vpc.default.id
# }

# data "aws_subnet" "default" {
#   id = data.aws_subnet_ids.default.ids[0]
# }

# Get *one* default subnet in the default VPC
data "aws_subnet" "default" {
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.default.id]
  }

  filter {
    name   = "default-for-az"
    values = ["true"]
  }

  availability_zone = "${var.region}a"
}

data "aws_security_group" "default" {
  name   = "default"
  vpc_id = data.aws_vpc.default.id
}


resource "aws_instance" "dl_x86_gpu" {
  ami           = "ami-063f6c7dfdd5c1488" # x86_64 DL Base AMI (Amazon Linux 2023)
  instance_type = "g4dn.xlarge"           # x86_64 GPU instance
  key_name      = "ec2-key-pair"          # replace with your actual key name

  # Use default VPC + subnet
  subnet_id                   = data.aws_subnet.default.id
  vpc_security_group_ids      = [data.aws_security_group.default.id]
  associate_public_ip_address = true

  root_block_device {
    volume_size = 100
    volume_type = "gp3"
  }

  tags = merge(
    local.common_tags,
    {
      Name = "dl-x86-gpu"
    }
  )
}
