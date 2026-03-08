/* output "vpc_subnet_ids" {
  description = "The IDs of the subnets in the VPC"
  value       = module.vpc.public_subnets
} */

output "ec2_instance_id" {
  description = "The ID of the EC2 instance"
  value       = aws_instance.default.public_ip
}

/* output "db_instance_endpoint" {
  description = "The endpoint of the RDS instance"
  value       = aws_db_instance.default.endpoint
} */