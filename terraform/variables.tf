variable "aws_region" {
  description = "AWS region to deploy resources"
  type        = string
  default     = "us-east-1" # Change to your preferred region
}

variable "project_name_prefix" {
  description = "A prefix for naming resources to ensure uniqueness and grouping"
  type        = string
  default     = "nyctaxi" # e.g., your-initials-nyctaxi
}

variable "s3_artifacts_bucket_name_suffix" {
  description = "Suffix for the S3 artifacts bucket"
  type        = string
  default     = "-artifacts-bucket"
}

variable "s3_data_bucket_name_suffix" {
  description = "Suffix for the S3 data bucket"
  type        = string
  default     = "-data-bucket"
}

variable "sns_email_endpoint" {
  description = "Email address for SNS notifications"
  type        = string
  # default     = "your-email@example.com" # Set this via -var or a .tfvars file
}

variable "lambda_zip_path" {
  description = "Path to the Lambda deployment package (zip file)"
  type        = string
  default     = "./lambda_package/NYCTaxiPostProcessor.zip"
}
