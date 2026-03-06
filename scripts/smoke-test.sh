#!/bin/bash
set -euo pipefail

ENVIRONMENT=${1:-staging}
REGION=${2:-us-east-1}

echo "==> Smoke testing $ENVIRONMENT environment"

# Check 1: VPC exists and is available
VPC_ID=$(terraform -chdir=environments/$ENVIRONMENT output -raw vpc_id)
VPC_STATE=$(aws ec2 describe-vpcs \
  --vpc-ids "$VPC_ID" \
  --query 'Vpcs[0].State' \
  --output text \
  --region "$REGION")

[[ "$VPC_STATE" == "available" ]] \
  && echo "✅ VPC: $VPC_ID is available" \
  || (echo "❌ VPC not available (state: $VPC_STATE)" && exit 1)

# Check 2: EC2 instance is running
INSTANCE_ID=$(terraform -chdir=environments/$ENVIRONMENT output -raw instance_id)
INSTANCE_STATE=$(aws ec2 describe-instances \
  --instance-ids "$INSTANCE_ID" \
  --query 'Reservations[0].Instances[0].State.Name' \
  --output text \
  --region "$REGION")

[[ "$INSTANCE_STATE" == "running" ]] \
  && echo "✅ EC2: $INSTANCE_ID is running" \
  || (echo "❌ EC2 not running (state: $INSTANCE_STATE)" && exit 1)

echo "==> All smoke tests passed. Deployment closed. ✅"