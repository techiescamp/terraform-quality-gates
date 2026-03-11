terraform {
  required_version = ">= 1.5.0"

  backend "s3" {
    bucket  = "techies-terraform"
    key     = "staging/vpc-ec2/terraform.tfstate"
    region  = "us-east-1"
    encrypt = true
  }
}

module "vpc" {
  source      = "../../modules/vpc"
  environment = var.environment
  aws_region  = var.aws_region
}

module "ec2" {
  source        = "../../modules/ec2"
  environment   = var.environment
  aws_region    = var.aws_region
  vpc_id        = module.vpc.vpc_id
  subnet_id     = module.vpc.subnet_id
  instance_type = var.instance_type
}