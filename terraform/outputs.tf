output "artifacts_s3_bucket_name" {
  description = "Name of the S3 bucket for artifacts"
  value       = aws_s3_bucket.artifacts_bucket.bucket
}

output "data_s3_bucket_name" {
  description = "Name of the S3 bucket for data (input/output)"
  value       = aws_s3_bucket.data_bucket.bucket
}

output "sns_topic_arn" {
  description = "ARN of the SNS topic for notifications"
  value       = aws_sns_topic.notifications.arn
}

output "lambda_function_name" {
  description = "Name of the Lambda function"
  value       = aws_lambda_function.post_processor_lambda.function_name
}
