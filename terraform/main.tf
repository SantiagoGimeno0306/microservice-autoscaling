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
  public_subnets  = ["10.0.101.0/24", "10.0.102.0/24"]

  enable_dns_hostnames = true
}

resource "aws_security_group" "ec2" {
  name        = "ingress-ec2"
  vpc_id      = module.vpc.vpc_id
  tags = {
    Name = "Terraform"
  }
}

resource "aws_vpc_security_group_ingress_rule" "ingress_ec2_ssh" {
  security_group_id = aws_security_group.ec2.id
  from_port         = 22
  to_port           = 22
  ip_protocol        = "tcp"
  cidr_ipv4 = var.local_ip_range
}

resource "aws_vpc_security_group_ingress_rule" "ingress_ec2_http" {
  security_group_id = aws_security_group.ec2.id
  from_port         = 8021
  to_port           = 8021
  ip_protocol        = "tcp"
  cidr_ipv4 = var.local_ip_range
}

resource "aws_vpc_security_group_egress_rule" "egress_all" {
  security_group_id = aws_security_group.ec2.id
  ip_protocol = "-1"
  cidr_ipv4 = "0.0.0.0/0"
}

resource "aws_security_group" "rds" {
  name        = "ingress-rds"
  description = "Allows EC2 instances to connect to RDS"
  vpc_id      = module.vpc.vpc_id
  tags = {
    Name = "Terraform"
  }
}

resource "aws_vpc_security_group_ingress_rule" "ingress_rds" {
  security_group_id = aws_security_group.rds.id
  from_port         = 5432
  to_port           = 5432
  ip_protocol        = "tcp"
  referenced_security_group_id = aws_security_group.ec2.id
}

data "aws_ami" "ubuntu" {
  most_recent = true

  filter {
    name   = "name"
    values = ["learn-packer-linux-aws-redis-*"]
  }

  owners = ["self", "099720109477"]
  
}

data "aws_iam_instance_profile" "this" {
  name = "ec2_read_s3_profile"
}

resource "aws_db_subnet_group" "rds" {
  name       = "rds-subnet-group"
  subnet_ids = module.vpc.private_subnets

  tags = {
    Name = "RDS subnet group"
  }
}

resource "aws_db_instance" "default" {
  allocated_storage    = 10
  db_name              = "postgres"
  engine               = data.aws_rds_engine_version.test.engine
  engine_version       = data.aws_rds_engine_version.test.version
  instance_class       = "db.t3.micro"
  username             = "postgres"
  password             = "arcoiris8"
  /* parameter_group_name = "default.postgre17.6" */
  skip_final_snapshot  = true
  vpc_security_group_ids = [aws_security_group.rds.id]
  db_subnet_group_name   = aws_db_subnet_group.rds.name
  
}

data "aws_rds_engine_version" "test" {
  engine             = "postgres"
  preferred_versions = ["17.6"]
}

resource "aws_launch_template" "ec2_lt" {
  name_prefix   = "ec2-lt-"
  image_id      = data.aws_ami.ubuntu.id
  instance_type = var.instance_type
  user_data = base64encode(templatefile("init_script.sh", {
      db_host = aws_db_instance.default.address
      db_name = aws_db_instance.default.db_name
      db_user = aws_db_instance.default.username
      db_pass = aws_db_instance.default.password
  }))

  iam_instance_profile {
    name = data.aws_iam_instance_profile.this.name
  }

  network_interfaces {
    device_index = 0
    security_groups = [module.vpc.default_security_group_id, aws_security_group.ec2.id]
    associate_public_ip_address = true
    /* subnet_id = module.vpc.public_subnets[0] */
  }

  key_name = "my-key"

  tag_specifications {
    resource_type = "instance"

    tags = {
      Name = "learn-ec2-instance"
    }
  }
}

/* resource "aws_instance" "default" {
  ami           = data.aws_ami.ubuntu.id
  launch_template {
    id      = aws_launch_template.ec2_lt.id
    version = "$Latest"
  }

  tags = {
    Name = "MyInstance"
  }
}  */

resource "aws_security_group" "terramino_lb" {
  name        = "terramino-lb-sg"
  description = "Security group for the ALB"
  vpc_id      = module.vpc.vpc_id
  tags = {
    Name = "Terraform"
  }
}

resource "aws_vpc_security_group_ingress_rule" "ingress_lb" {
  security_group_id = aws_security_group.terramino_lb.id
  from_port         = 8021
  to_port           = 8021
  ip_protocol        = "tcp"
  cidr_ipv4 = var.local_ip_range
}

resource "aws_vpc_security_group_egress_rule" "egress_lb" {
  security_group_id = aws_security_group.terramino_lb.id
  from_port         = 8021
  to_port           = 8021
  ip_protocol        = "tcp"
  referenced_security_group_id = aws_security_group.ec2.id
}

resource "aws_vpc_security_group_ingress_rule" "ingress_ec2_from_alb" {
  security_group_id = aws_security_group.ec2.id
  from_port         = 8021
  to_port           = 8021
  ip_protocol       = "tcp"
  referenced_security_group_id = aws_security_group.terramino_lb.id
}

resource "aws_lb" "terramino" { 
  name = "learn-asg-terramino-lb" 
  internal = false 
  load_balancer_type = "application" 
  security_groups = [aws_security_group.terramino_lb.id] 
  subnets = module.vpc.public_subnets 
} 

resource "aws_lb_listener" "terramino_users" { 
  load_balancer_arn = aws_lb.terramino.arn 
  port = "8021" 
  
  protocol = "HTTP" 
  default_action { 
    type = "forward" 
    target_group_arn = aws_lb_target_group.terramino.arn 
    } 
} 

resource "aws_lb_target_group" "terramino" { 
  name = "learn-asg-terramino" 
  port = 8021
  protocol = "HTTP" 
  vpc_id = module.vpc.vpc_id 
  health_check {
    path    = "/actuator/health"
    matcher = "200"
    unhealthy_threshold = 5
    timeout = 10
    port = 8021
  }
  deregistration_delay = 30
}

resource "aws_autoscaling_group" "terramino" {
min_size             = 1
max_size             = 3
desired_capacity     = 1
launch_template {
    id      = aws_launch_template.ec2_lt.id
    version = "$Latest"
  }
vpc_zone_identifier  = module.vpc.public_subnets
target_group_arns = [aws_lb_target_group.terramino.arn]
health_check_grace_period = 60

}

resource "aws_autoscaling_policy" "scale_up" {
  name                   = "scale-up"
  autoscaling_group_name = aws_autoscaling_group.terramino.name
  adjustment_type        = "StepScaling"
  target_tracking_configuration {
    target_value = 2
    predefined_metric_specification {
      predefined_metric_type = "ASGAverageCPUUtilization"
    }
  }
}

data "aws_instances" "asg_instances" {
  filter {
    name   = "tag:aws:autoscaling:groupName"
    values = [aws_autoscaling_group.terramino.name]
  }
}