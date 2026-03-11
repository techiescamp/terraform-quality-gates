package test

import (
  "testing"
  "github.com/gruntwork-io/terratest/modules/terraform"
  "github.com/gruntwork-io/terratest/modules/aws"
  "github.com/stretchr/testify/assert"
)

func TestVpcEc2Module(t *testing.T) {
  t.Parallel()

  terraformOptions := terraform.WithDefaultRetryableErrors(t, &terraform.Options{
    TerraformDir: "../environments/dev",
    VarFiles:     []string{"../../vars/dev/dev.tfvars"},
  })

  // CRITICAL: defer destroy runs even if assertions fail — no orphaned resources
  defer terraform.Destroy(t, terraformOptions)

  // Step 1: init + apply
  terraform.InitAndApply(t, terraformOptions)

  // Step 2: Read outputs
  vpcID      := terraform.Output(t, terraformOptions, "vpc_id")
  instanceID := terraform.Output(t, terraformOptions, "instance_id")

  // Step 3: Assert outputs are non-empty
  assert.NotEmpty(t, vpcID, "VPC ID should not be empty")
  assert.NotEmpty(t, instanceID, "Instance ID should not be empty")

  // Step 4: Verify VPC actually exists in AWS
  vpc := aws.GetVpcById(t, vpcID, "us-east-1")
  assert.NotNil(t, vpc, "VPC should exist")
  assert.Equal(t, vpcID, vpc.Id, "VPC ID should match")

  // Step 5: Verify EC2 instance exists
  tags := aws.GetTagsForEc2Instance(t, "us-east-1", instanceID)
  assert.NotNil(t, tags, "EC2 instance tags should exist")
}