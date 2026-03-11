output "vpc_id" {
  value       = module.vpc.vpc_id
  description = "The ID of the VPC"
}

output "instance_id" {
  value       = module.ec2.instance_id
  description = "The ID of the EC2 instance"
}
