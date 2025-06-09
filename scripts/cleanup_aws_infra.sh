#!/bin/bash
set -e

TERRAFORM_DIR="../terraform"

echo "Destroying AWS infrastructure with Terraform..."
(cd "$TERRAFORM_DIR" && terraform destroy -auto-approve)

echo "AWS infrastructure cleanup complete."
