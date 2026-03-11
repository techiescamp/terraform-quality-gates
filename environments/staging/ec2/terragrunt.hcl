include "root" {
  path = find_in_parent_folders()
}

terraform {
  source = "../../../modules/ec2"
}

dependency "vpc" {
  config_path = "../vpc"

  mock_outputs = {
    vpc_id    = "vpc-mock123"
    subnet_id = "subnet-mock123"
  }
}

inputs = {
  environment   = "staging"
  aws_region    = "us-east-1"
  instance_type = "t2.micro"
  vpc_id        = dependency.vpc.outputs.vpc_id
  subnet_id     = dependency.vpc.outputs.subnet_id
}
