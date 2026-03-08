output "vpc_subnet_ids" {
  description = "The IDs of the subnets in the VPC"
  value       = module.vpc.public_subnets
}

/* output "ec2_instance_id" {
  description = "The ID of the EC2 instance"
  value       = aws_instance.default.public_ip
} */

output "alb_ip" {
  description = "The IP address of the ALB"
  value       = aws_lb.terramino.dns_name
}

output "asg_public_ips" {
  value = data.aws_instances.asg_instances.public_ips
}

output "alb_health_check" {
  description = "The health check configuration of the ALB target group"
  value       = aws_lb_target_group.terramino.health_check
}

output "db_instance_endpoint" {
  description = "The endpoint of the RDS instance"
  value       = aws_db_instance.default.endpoint
}