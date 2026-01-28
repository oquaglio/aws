# =============================================================================
# Assumable Role (simulates a role in a "target" account)
# In a real cross-account scenario, this role would exist in Account B
# =============================================================================

resource "aws_iam_role" "cross_account_s3_role" {
  name = "${var.project_name}-cross-account-s3-role"

  # Trust policy: Allow the Lambda execution role to assume this role
  # In real cross-account, the principal would reference a different account ID
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "AllowLambdaRoleToAssume"
        Effect = "Allow"
        Principal = {
          AWS = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/${var.project_name}-lambda-execution-role"
        }
        Action = "sts:AssumeRole"
        Condition = {
          StringEquals = {
            "sts:ExternalId" = "${var.project_name}-external-id"
          }
        }
      }
    ]
  })
}

# Policy attached to the assumable role granting S3 permissions
resource "aws_iam_role_policy" "cross_account_s3_policy" {
  name = "${var.project_name}-s3-access-policy"
  role = aws_iam_role.cross_account_s3_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "S3BucketAccess"
        Effect = "Allow"
        Action = [
          "s3:GetObject",
          "s3:PutObject",
          "s3:ListBucket",
          "s3:DeleteObject"
        ]
        Resource = [
          aws_s3_bucket.target_bucket.arn,
          "${aws_s3_bucket.target_bucket.arn}/*"
        ]
      }
    ]
  })
}

# =============================================================================
# Lambda Execution Role (simulates a role in "source" account)
# In a real cross-account scenario, this role would exist in Account A
# =============================================================================

resource "aws_iam_role" "lambda_execution_role" {
  name = "${var.project_name}-lambda-execution-role"

  # Trust policy: Allow Lambda service to assume this role
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Service = "lambda.amazonaws.com"
        }
        Action = "sts:AssumeRole"
      }
    ]
  })
}

# Policy allowing Lambda to write logs
resource "aws_iam_role_policy" "lambda_logging" {
  name = "${var.project_name}-lambda-logging"
  role = aws_iam_role.lambda_execution_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents"
        ]
        Resource = "arn:aws:logs:*:*:*"
      }
    ]
  })
}

# Policy allowing Lambda to assume the "cross-account" role
resource "aws_iam_role_policy" "lambda_assume_role" {
  name = "${var.project_name}-assume-cross-account-role"
  role = aws_iam_role.lambda_execution_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid      = "AllowAssumeTargetRole"
        Effect   = "Allow"
        Action   = "sts:AssumeRole"
        Resource = aws_iam_role.cross_account_s3_role.arn
      }
    ]
  })
}
