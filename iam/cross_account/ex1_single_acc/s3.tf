# S3 bucket (simulates a bucket in a "target" account)
# This bucket will be accessed by the Lambda via role assumption

resource "aws_s3_bucket" "target_bucket" {
  bucket = "${var.project_name}-bucket-${data.aws_caller_identity.current.account_id}"
}

resource "aws_s3_bucket_versioning" "target_bucket" {
  bucket = aws_s3_bucket.target_bucket.id
  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "target_bucket" {
  bucket = aws_s3_bucket.target_bucket.id
  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

resource "aws_s3_bucket_public_access_block" "target_bucket" {
  bucket = aws_s3_bucket.target_bucket.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# Bucket policy that allows the assumable role to access the bucket
# In a real cross-account scenario, this role would be in a different account
resource "aws_s3_bucket_policy" "target_bucket" {
  bucket = aws_s3_bucket.target_bucket.id
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "AllowAssumedRoleAccess"
        Effect = "Allow"
        Principal = {
          AWS = aws_iam_role.cross_account_s3_role.arn
        }
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

# Sample object to demonstrate access
resource "aws_s3_object" "sample" {
  bucket  = aws_s3_bucket.target_bucket.id
  key     = "sample/hello.txt"
  content = "Hello from cross-account S3 access demo!"
}
