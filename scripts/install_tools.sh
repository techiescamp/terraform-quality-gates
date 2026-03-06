#!/bin/bash

# Exit on any error
set -e

echo "Starting installation of Terraform Quality Gates tools..."

# Update package lists
sudo apt update

# 1. Install unzip (required by tflint script)
echo "Installing unzip..."
sudo apt install unzip -y

# 2. Install Terraform
echo "Installing Terraform..."
# Install prerequisites for adding new repositories
sudo apt-get install -y gnupg software-properties-common wget

# Install the HashiCorp GPG key
wget -O- https://apt.releases.hashicorp.com/gpg | \
gpg --dearmor | \
sudo tee /usr/share/keyrings/hashicorp-archive-keyring.gpg > /dev/null

# Add the official HashiCorp repository
echo "deb [signed-by=/usr/share/keyrings/hashicorp-archive-keyring.gpg] \
https://apt.releases.hashicorp.com $(lsb_release -cs) main" | \
sudo tee /etc/apt/sources.list.d/hashicorp.list

# Update system and install terraform
sudo apt update
sudo apt-get install terraform -y

# 3. Install TFLint
echo "Installing TFLint..."
curl -s https://raw.githubusercontent.com/terraform-linters/tflint/master/install_linux.sh | bash

# 4. Install Checkov
echo "Installing Checkov..."
# Ubuntu 24.04 blocks system-wide pip, so we use pipx
sudo apt install pipx -y
pipx install checkov
pipx ensurepath
echo "Checkov installed. Remember to run 'source ~/.bashrc' or restart your terminal if it's not in your PATH."

# 5. Install TFSec
echo "Installing TFSec..."
sudo wget -qO /usr/local/bin/tfsec https://github.com/aquasecurity/tfsec/releases/latest/download/tfsec-linux-amd64
sudo chmod +x /usr/local/bin/tfsec

# 6. Install AWS CLI v2
echo "Installing AWS CLI..."
curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
unzip -o awscliv2.zip
sudo ./aws/install --update
rm awscliv2.zip
rm -rf aws

# 7. Install OPA
echo "Installing OPA..."
curl -L -o /usr/local/bin/opa https://openpolicyagent.org/downloads/latest/opa_linux_amd64_static
sudo chmod +x /usr/local/bin/opa

# 8. Install Infracost
echo "Installing Infracost..."
curl -fsSL https://raw.githubusercontent.com/infracost/infracost/master/scripts/install.sh | sh

echo ""
echo "========================================="
echo "Installation Complete!"
echo "========================================="
echo "Verifying versions:"
terraform version
echo "---"
tflint --version
echo "---"
/home/ubuntu/.local/bin/checkov --version
echo "---"
tfsec --version
echo "---"
aws --version
echo "---"
opa version
echo "---"
infracost --version
echo "========================================="
