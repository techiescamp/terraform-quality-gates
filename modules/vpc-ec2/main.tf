provider "aws" {
  region = var.aws_region
}

resource "aws_vpc" "main" {
  cidr_block           = var.vpc_cidr
  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = {
    Name        = "${var.environment}-vpc"
    Environment = var.environment
  }
}

resource "aws_subnet" "public" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = cidrsubnet(var.vpc_cidr, 8, 1)
  map_public_ip_on_launch = false
  availability_zone       = "${var.aws_region}a"

  tags = {
    Name        = "${var.environment}-public-subnet"
    Environment = var.environment
  }
}

resource "aws_internet_gateway" "main" {
  vpc_id = aws_vpc.main.id
  tags   = { Name = "${var.environment}-igw" }
}

resource "aws_security_group" "web" {
  name        = "${var.environment}-web-sg"
  description = "Allow HTTPS inbound traffic"
  vpc_id      = aws_vpc.main.id

  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    description = "HTTPS from internet"
  }

  # Checkov CKV_AWS_382: Ensure no security groups allow egress from 0.0.0.0:0 to port -1
  # Removing the overly permissive egress rule. Add specific egress rules as needed for your application.
  # egress {
  #   from_port   = 0
  #   to_port     = 0
  #   protocol    = "-1"
  #   cidr_blocks = ["0.0.0.0/0"]
  #   description = "Allow all outbound"
  # }
}

data "aws_ami" "amazon_linux" {
  most_recent = true
  owners      = ["amazon"]
  filter {
    name   = "name"
    values = ["al2023-ami-*-x86_64"]
  }
}

resource "aws_instance" "web" {
  ami                    = data.aws_ami.amazon_linux.id
  instance_type          = var.instance_type
  subnet_id              = aws_subnet.public.id
  vpc_security_group_ids = [aws_security_group.web.id]

  ebs_optimized = true # CKV_AWS_135
  monitoring    = true # CKV_AWS_126

  iam_instance_profile = aws_iam_instance_profile.web_profile.name # CKV2_AWS_41

  metadata_options {
    http_tokens = "required" # IMDSv2 — required by checkov
  }

  root_block_device {
    encrypted = true # required by checkov
  }

  tags = {
    Name        = "${var.environment}-web"
    Environment = var.environment
  }
}

resource "aws_s3_bucket" "bad_example" {
  bucket = "my-test-bucket-open"
}

# CKV2_AWS_11: Ensure VPC flow logging is enabled in all VPCs
resource "aws_flow_log" "main" {
  log_destination      = aws_cloudwatch_log_group.vpc_flow_log.arn
  log_destination_type = "cloud-watch-logs"
  traffic_type         = "ALL"
  vpc_id               = aws_vpc.main.id
  iam_role_arn         = aws_iam_role.vpc_flow_log_role.arn
}

resource "aws_cloudwatch_log_group" "vpc_flow_log" {
  name              = "/aws/vpc/${var.environment}-flow-log"
  retention_in_days = 7
  # CKV_AWS_158 Ensure that CloudWatch Log Group is encrypted by KMS (skipped for simplicity, but in prod add kms_key_id)
}

resource "aws_iam_role" "vpc_flow_log_role" {
  name = "${var.environment}-vpc-flow-log-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "vpc-flow-logs.amazonaws.com"
        }
      }
    ]
  })
}

resource "aws_iam_role_policy" "vpc_flow_log_policy" {
  name = "${var.environment}-vpc-flow-log-policy"
  role = aws_iam_role.vpc_flow_log_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents",
          "logs:DescribeLogGroups",
          "logs:DescribeLogStreams"
        ]
        Effect   = "Allow"
        Resource = "*"
      }
    ]
  })
}

# CKV2_AWS_12: Ensure the default security group of every VPC restricts all traffic
resource "aws_default_security_group" "default" {
  vpc_id = aws_vpc.main.id
}

# CKV2_AWS_41: Ensure an IAM role is attached to EC2 instance
resource "aws_iam_role" "web_role" {
  name = "${var.environment}-web-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "ec2.amazonaws.com"
        }
      }
    ]
  })
}

resource "aws_iam_instance_profile" "web_profile" {
  name = "${var.environment}-web-profile"
  role = aws_iam_role.web_role.name
}