#!/bin/bash
set -e

echo "Starting Full NYC Taxi Analysis Pipeline..."

echo "Step 1: Downloading data..."
./download_data.sh

echo "Step 2: Building Java project..."
./build_java_project.sh

echo "Step 3: Deploying AWS Infrastructure..."
./deploy_aws_infra.sh

echo "Step 4: Running MapReduce job in Docker..."
./run_mapreduce_docker.sh

echo "Step 5: Uploading MapReduce output to S3 (will trigger Lambda)..."
./upload_to_s3.sh

echo "Step 6: Performing local post-processing for verification..."
python3 ../DataInvestigation/get_top_n.py ../data/output_local/mapreduce_output.txt

echo "---------------------------------------------------------------------"
echo "PIPELINE COMPLETED!"
echo "Check your email for SNS notification from AWS Lambda."
echo "Check CloudWatch Logs for Lambda execution details."
echo "You can now manually run ./cleanup_aws_infra.sh to destroy AWS resources."
echo "---------------------------------------------------------------------"
