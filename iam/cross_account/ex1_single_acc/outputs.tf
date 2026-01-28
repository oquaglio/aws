# =============================================================================
# S3 Bucket Outputs
# =============================================================================

output "bucket_name" {
  description = "Name of the S3 bucket"
  value       = aws_s3_bucket.target_bucket.id
}

output "bucket_arn" {
  description = "ARN of the S3 bucket"
  value       = aws_s3_bucket.target_bucket.arn
}

# =============================================================================
# IAM Role Outputs
# =============================================================================

output "assumable_role_arn" {
  description = "ARN of the assumable role (would be in target account in real cross-account)"
  value       = aws_iam_role.cross_account_s3_role.arn
}

output "lambda_execution_role_arn" {
  description = "ARN of the Lambda execution role (would be in source account in real cross-account)"
  value       = aws_iam_role.lambda_execution_role.arn
}

# =============================================================================
# Lambda Outputs
# =============================================================================

output "lambda_function_name" {
  description = "Name of the Lambda function"
  value       = aws_lambda_function.cross_account_s3.function_name
}

output "lambda_function_arn" {
  description = "ARN of the Lambda function"
  value       = aws_lambda_function.cross_account_s3.arn
}

# =============================================================================
# Testing Instructions
# =============================================================================

output "test_commands" {
  description = "AWS CLI commands to test the Lambda function"
  value       = <<-EOT

    # Test listing objects in the bucket (via role assumption):
    aws lambda invoke \
      --function-name ${aws_lambda_function.cross_account_s3.function_name} \
      --payload '{"operation": "list"}' \
      --cli-binary-format raw-in-base64-out \
      response.json && cat response.json

    # Test reading an object:
    aws lambda invoke \
      --function-name ${aws_lambda_function.cross_account_s3.function_name} \
      --payload '{"operation": "read", "key": "sample/hello.txt"}' \
      --cli-binary-format raw-in-base64-out \
      response.json && cat response.json

    # Test writing an object:
    aws lambda invoke \
      --function-name ${aws_lambda_function.cross_account_s3.function_name} \
      --payload '{"operation": "write", "key": "test/from-lambda.txt", "content": "Written via role assumption!"}' \
      --cli-binary-format raw-in-base64-out \
      response.json && cat response.json

  EOT
}
