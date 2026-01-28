# =============================================================================
# Lambda function that assumes the "cross-account" role
# In a real scenario, this would be deployed in the source account (Account A)
# =============================================================================

# Package the Lambda function code
data "archive_file" "lambda_zip" {
  type        = "zip"
  source_file = "${path.module}/lambda/cross_account_s3.py"
  output_path = "${path.module}/lambda/cross_account_s3.zip"
}

# Lambda function
resource "aws_lambda_function" "cross_account_s3" {
  filename         = data.archive_file.lambda_zip.output_path
  function_name    = "${var.project_name}-cross-account-s3"
  role             = aws_iam_role.lambda_execution_role.arn
  handler          = "cross_account_s3.lambda_handler"
  source_code_hash = data.archive_file.lambda_zip.output_base64sha256
  runtime          = "python3.12"
  timeout          = 30
  memory_size      = 128

  environment {
    variables = {
      TARGET_ROLE_ARN    = aws_iam_role.cross_account_s3_role.arn
      TARGET_BUCKET_NAME = aws_s3_bucket.target_bucket.id
      EXTERNAL_ID        = "${var.project_name}-external-id"
    }
  }
}

# CloudWatch Log Group for Lambda
resource "aws_cloudwatch_log_group" "lambda_logs" {
  name              = "/aws/lambda/${aws_lambda_function.cross_account_s3.function_name}"
  retention_in_days = 7
}
