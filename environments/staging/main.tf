terraform {
  required_version = ">= 1.5.0"

  backend "s3" {
    bucket  = "techies-terraform"
    key     = "staging/vpc-ec2/terraform.tfstate"
    region  = "us-east-1"
    encrypt = true
  }
}

module "vpc_ec2" {
  source        = "../../modules/vpc-ec2"
  environment   = "staging"
  instance_type = "t2.micro"
  aws_region    = "us-east-1"

}