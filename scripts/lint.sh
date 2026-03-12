#!/bin/bash
# scripts/lint.sh
# Usage: ./scripts/lint.sh <path-to-terragrunt-module>
# Example: ./scripts/lint.sh environments/dev/ec2

set -e

TARGET_DIR=$1

if [ -z "$TARGET_DIR" ]; then
    echo "Usage: $0 <path-to-terragrunt-module>"
    exit 1
fi

echo "🔍 Linting $TARGET_DIR..."

# 1. Get the source module path from Terragrunt
MODULE_SOURCE=$(terragrunt render-json --terragrunt-working-dir "$TARGET_DIR" | jq -r '.terraform.source')

# 2. Get the actual variables/inputs from Terragrunt
# We'll convert them to tflint --var flags
VARS=$(terragrunt render-json --terragrunt-working-dir "$TARGET_DIR" | jq -r '.inputs | to_entries | .[] | "--var '\''" + .key + "=" + (.value | tostring) + "'\''"')

# 3. Run tflint against the source module with the correct variables
# Note: We assume the source is relative to the terragrunt file or absolute. 
# For this project, it's usually ../../../modules/xxx
cd "$TARGET_DIR"
cd "$MODULE_SOURCE"

eval "tflint --config $(git rev-parse --show-toplevel)/.tflint.hcl $VARS"
