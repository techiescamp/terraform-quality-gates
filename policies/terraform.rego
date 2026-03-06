package terraform.policies

# DENY: security group that opens port 22 to the world
deny contains msg if {
  resource := input.resource_changes[_]
  resource.type == "aws_security_group"
  resource.change.after.ingress[_].from_port == 22
  resource.change.after.ingress[_].cidr_blocks[_] == "0.0.0.0/0"
  msg := sprintf("POLICY VIOLATION: Security group '%v' opens port 22 to 0.0.0.0/0",
    [resource.address])
}

# DENY: destroying any resource tagged prod without manual approval
deny contains msg if {
  resource := input.resource_changes[_]
  resource.change.actions[_] == "delete"
  resource.change.before.tags.Environment == "prod"
  msg := sprintf("POLICY VIOLATION: Destroying prod resource '%v' requires manual approval",
    [resource.address])
}