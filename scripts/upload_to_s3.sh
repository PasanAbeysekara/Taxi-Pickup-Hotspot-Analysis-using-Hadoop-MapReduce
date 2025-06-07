#!/bin/bash
set -e

TERRAFORM_DIR="../terraform"
LOCAL_MAPREDUCE_OUTPUT="../data/output_local/mapreduce_output.txt"
S3_OBJECT_KEY="output/mapreduce_results.txt" # Key within the S3 bucket

echo "Fetching S3 bucket name from Terraform outputs..."
# This assumes your Terraform output is named 'data_s3_bucket_name'
S3_BUCKET_NAME=$(cd "$TERRAFORM_DIR" && terraform output -raw data_s3_bucket_name)

if [ -z "$S3_BUCKET_NAME" ]; then
    echo "Error: Could not retrieve S3 bucket name from Terraform outputs."
    exit 1
fi

echo "Uploading MapReduce output to S3 bucket: $S3_BUCKET_NAME with key: $S3_OBJECT_KEY"
aws s3 cp "$LOCAL_MAPREDUCE_OUTPUT" "s3://$S3_BUCKET_NAME/$S3_OBJECT_KEY"

echo "Upload to S3 complete. This should trigger the Lambda."
