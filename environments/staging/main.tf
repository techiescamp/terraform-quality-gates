terraform {
  required_version = ">= 1.5.0"
}

module "vpc_ec2" {
  source        = "../../modules/vpc-ec2"
  environment   = "staging"
  instance_type = "t2.micro"
  aws_region    = "us-east-1"

}