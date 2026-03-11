include "root" {
  path = find_in_parent_folders()
}

terraform {
  source = "../../../modules/vpc"
}

inputs = {
  environment = "dev"
  aws_region  = "us-east-1"
}
