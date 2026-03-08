provider "aws" {
  region = var.aws_region
  default_tags {
      tags = {
     Terraform = true
   }
  }
}

module "vpc" {
  source = "terraform-aws-modules/vpc/aws"

  name               = "main-vpc"
  cidr               = "10.0.0.0/16"
  enable_nat_gateway = false

  azs             = ["us-east-1a", "us-east-1b", "us-east-1c"]
  private_subnets = ["10.0.1.0/24", "10.0.2.0/24"]
  public_subnets  = ["10.0.101.0/24"]

  enable_dns_hostnames = true
}

resource "aws_security_group" "ec2" {
  name        = "ingress-ec2"
  description = "Allows me to ssh to EC2 instances"
  vpc_id      = module.vpc.vpc_id
  tags = {
    Name = "Terraform"
  }
}

resource "aws_vpc_security_group_ingress_rule" "ingress_ec2" {
  security_group_id = aws_security_group.ec2.id
  from_port         = 22
  to_port           = 22
  ip_protocol        = "tcp"
  cidr_ipv4 = "79.116.138.0/24"
}

data "aws_iam_instance_profile" "this" {
  name = "ec2_read_s3_profile"
}

data "aws_ami" "ubuntu" {
  most_recent = true

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-jammy-22.04-amd64-server-*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }

  owners = ["099720109477"] # Canonical
}

resource "aws_launch_template" "ec2_lt" {
  name_prefix   = "ec2-lt-"
  image_id      = data.aws_ami.ubuntu.id
  instance_type = "t2.nano"
  user_data = base64encode(templatefile("init_script.sh", {
      db_host = "1"
      db_name = "2"
      db_user = "3"
      db_pass = "4"
  }))

  iam_instance_profile {
    name = data.aws_iam_instance_profile.this.name
  }

  network_interfaces {
    device_index = 0
    security_groups = [module.vpc.default_security_group_id, aws_security_group.ec2.id]
    associate_public_ip_address = true
    subnet_id = module.vpc.public_subnets[0]
  }

  key_name = "my-key"

  tag_specifications {
    resource_type = "instance"

    tags = {
      Name = "learn-ec2-instance"
    }
  }
}

resource "aws_instance" "default" {
  launch_template {
    id      = aws_launch_template.ec2_lt.id
    version = "$Latest"
  }

  

  tags = {
    Name = "MyInstance"
  }
}