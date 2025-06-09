#!/bin/bash
set -e

TERRAFORM_DIR="../terraform"
LAMBDA_PACKAGE_DIR="$TERRAFORM_DIR/lambda_package"
LAMBDA_FUNCTION_FILE="lambda_function.py" # Assuming it's in the same dir as this script or copied
LAMBDA_ZIP_FILE="NYCTaxiPostProcessor.zip"

echo "Preparing Lambda package..."
# Copy your actual Lambda source to lambda_package if it's elsewhere
cp ../DataInvestigation/get_top_n_aws_lambda.py "$LAMBDA_PACKAGE_DIR/$LAMBDA_FUNCTION_FILE" # RENAME YOUR SCRIPT

(cd "$LAMBDA_PACKAGE_DIR" && zip "$LAMBDA_ZIP_FILE" "$LAMBDA_FUNCTION_FILE")

echo "Deploying AWS infrastructure with Terraform..."
(cd "$TERRAFORM_DIR" && terraform init && terraform apply -auto-approve)

echo "AWS infrastructure deployment complete."
