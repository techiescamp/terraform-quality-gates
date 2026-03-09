provider "aws" {
  region = var.aws_region
}

resource "aws_security_group" "web" {
  name        = "${var.environment}-web-sg"
  description = "Allow HTTPS inbound traffic"
  vpc_id      = var.vpc_id

  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    description = "HTTPS from internet"
  }

  # egress rules are intentionally omitted per the original specification
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
  subnet_id              = var.subnet_id
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
