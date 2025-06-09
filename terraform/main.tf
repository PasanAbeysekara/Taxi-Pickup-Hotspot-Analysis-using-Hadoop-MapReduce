provider "aws" {
  region = var.aws_region
}

data "aws_caller_identity" "current" {}
data "aws_region" "current_region" {}

locals {
  account_id = data.aws_caller_identity.current.account_id
  s3_artifacts_bucket_name = lower("${var.project_name_prefix}${var.s3_artifacts_bucket_name_suffix}-${local.account_id}-${data.aws_region.current_region.name}")
  s3_data_bucket_name      = lower("${var.project_name_prefix}${var.s3_data_bucket_name_suffix}-${local.account_id}-${data.aws_region.current_region.name}")
}

resource "aws_s3_bucket" "artifacts_bucket" {
  bucket = local.s3_artifacts_bucket_name
  # acl    = "private" # S3 Block Public Access is generally preferred

  tags = {
    Name        = "${var.project_name_prefix}-artifacts"
    Environment = "dev"
  }
}

resource "aws_s3_bucket_public_access_block" "artifacts_bucket_public_access" {
  bucket                  = aws_s3_bucket.artifacts_bucket.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}


resource "aws_s3_bucket" "data_bucket" {
  bucket = local.s3_data_bucket_name
  # acl    = "private"

  tags = {
    Name        = "${var.project_name_prefix}-data"
    Environment = "dev"
  }
}
resource "aws_s3_bucket_public_access_block" "data_bucket_public_access" {
  bucket                  = aws_s3_bucket.data_bucket.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# IAM Role for Lambda
resource "aws_iam_role" "lambda_exec_role" {
  name = "${var.project_name_prefix}-lambda-role"

  assume_role_policy = jsonencode({
    Version   = "2012-10-17"
    Statement = [
      {
        Action    = "sts:AssumeRole"
        Effect    = "Allow"
        Principal = {
          Service = "lambda.amazonaws.com"
        }
      },
    ]
  })
}

resource "aws_iam_policy" "lambda_policy" {
  name        = "${var.project_name_prefix}-lambda-policy"
  description = "Policy for Lambda to access S3 and SNS"

  policy = jsonencode({
    Version   = "2012-10-17"
    Statement = [
      {
        Effect   = "Allow"
        Action   = [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents"
        ]
        Resource = "arn:aws:logs:*:*:*"
      },
      {
        Effect   = "Allow"
        Action   = "s3:GetObject"
        Resource = "${aws_s3_bucket.data_bucket.arn}/output/*" # Only allow access to the output prefix
      },
      {
        Effect   = "Allow"
        Action   = "sns:Publish"
        Resource = aws_sns_topic.notifications.arn # Allow publishing to our specific topic
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "lambda_policy_attach" {
  role       = aws_iam_role.lambda_exec_role.name
  policy_arn = aws_iam_policy.lambda_policy.arn
}

# SNS Topic
resource "aws_sns_topic" "notifications" {
  name = "${var.project_name_prefix}-notifications"
}

# SNS Subscription (only if email is provided)
resource "aws_sns_topic_subscription" "email_subscription" {
  count     = var.sns_email_endpoint != "" ? 1 : 0 # Create only if email is set
  topic_arn = aws_sns_topic.notifications.arn
  protocol  = "email"
  endpoint  = var.sns_email_endpoint
}

# Lambda Function
resource "aws_lambda_function" "post_processor_lambda" {
  filename      = var.lambda_zip_path
  function_name = "${var.project_name_prefix}-post-processor"
  role          = aws_iam_role.lambda_exec_role.arn
  handler       = "lambda_function.lambda_handler" # Assumes lambda_function.py and handler named lambda_handler
  runtime       = "python3.9"
  timeout       = 120 # 2 minutes
  memory_size   = 256 # MB

  environment {
    variables = {
      SNS_TOPIC_ARN = aws_sns_topic.notifications.arn
    }
  }

  source_code_hash = filebase64sha256(var.lambda_zip_path) # Ensures Lambda updates if zip changes

  tags = {
    Name        = "${var.project_name_prefix}-post-processor-lambda"
    Environment = "dev"
  }
}

# S3 Bucket Notification to trigger Lambda
resource "aws_s3_bucket_notification" "bucket_notification" {
  bucket = aws_s3_bucket.data_bucket.id

  lambda_function {
    lambda_function_arn = aws_lambda_function.post_processor_lambda.arn
    events              = ["s3:ObjectCreated:Put"] # Trigger on PUT/new object creation
    filter_prefix       = "output/"
    filter_suffix       = ".txt" # Or be more specific like part-r-00000.txt
  }

  depends_on = [aws_lambda_permission.allow_s3_to_call_lambda]
}

# Permission for S3 to invoke Lambda
resource "aws_lambda_permission" "allow_s3_to_call_lambda" {
  statement_id  = "AllowS3ToCallLambda"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.post_processor_lambda.function_name
  principal     = "s3.amazonaws.com"
  source_arn    = aws_s3_bucket.data_bucket.arn
  # To be more secure, you can add source_account
  # source_account = local.account_id 
}
