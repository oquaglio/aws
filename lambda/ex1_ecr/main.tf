# Get current AWS account and region
data "aws_caller_identity" "current" {}
data "aws_region" "current" {}

locals {
  account_id = data.aws_caller_identity.current.account_id
  region     = data.aws_region.current.id
  ecr_url    = "${local.account_id}.dkr.ecr.${local.region}.amazonaws.com"
  image_uri  = "${aws_ecr_repository.lambda.repository_url}:${var.image_tag}"
}

# =============================================================================
# ECR Repository
# =============================================================================

resource "aws_ecr_repository" "lambda" {
  name                 = var.ecr_repository_name
  image_tag_mutability = "MUTABLE"
  force_delete         = true

  image_scanning_configuration {
    scan_on_push = true
  }

  tags = var.tags
}

# ECR Lifecycle Policy - keep only the latest N images
resource "aws_ecr_lifecycle_policy" "lambda" {
  repository = aws_ecr_repository.lambda.name

  policy = jsonencode({
    rules = [
      {
        rulePriority = 1
        description  = "Keep only the last ${var.image_retention_count} images"
        selection = {
          tagStatus   = "any"
          countType   = "imageCountMoreThan"
          countNumber = var.image_retention_count
        }
        action = {
          type = "expire"
        }
      }
    ]
  })
}

# =============================================================================
# Docker Image Build and Push
# =============================================================================

resource "null_resource" "docker_build_push" {
  triggers = {
    dockerfile_hash = filemd5("${path.module}/src/Dockerfile")
    app_hash        = filemd5("${path.module}/src/app.py")
    image_tag       = var.image_tag
  }

  provisioner "local-exec" {
    command = <<-EOT
      # Login to ECR
      aws ecr get-login-password --region ${local.region} | docker login --username AWS --password-stdin ${local.ecr_url}

      # Build the Docker image
      docker build -t ${aws_ecr_repository.lambda.repository_url}:${var.image_tag} ${path.module}/src

      # Push the image to ECR
      docker push ${aws_ecr_repository.lambda.repository_url}:${var.image_tag}
    EOT
  }

  depends_on = [aws_ecr_repository.lambda]
}

# =============================================================================
# IAM Role for Lambda
# =============================================================================

resource "aws_iam_role" "lambda" {
  name = "${var.lambda_function_name}-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "lambda.amazonaws.com"
        }
      }
    ]
  })

  tags = var.tags
}

# Attach basic execution policy for CloudWatch Logs
resource "aws_iam_role_policy_attachment" "lambda_basic" {
  role       = aws_iam_role.lambda.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

# =============================================================================
# Lambda Function
# =============================================================================

resource "aws_lambda_function" "main" {
  function_name = var.lambda_function_name
  role          = aws_iam_role.lambda.arn
  package_type  = "Image"
  image_uri     = local.image_uri
  timeout       = var.lambda_timeout
  memory_size   = var.lambda_memory_size

  environment {
    variables = {
      ENVIRONMENT = var.environment
    }
  }

  tags = var.tags

  depends_on = [
    null_resource.docker_build_push,
    aws_iam_role_policy_attachment.lambda_basic
  ]
}

# CloudWatch Log Group for Lambda
resource "aws_cloudwatch_log_group" "lambda" {
  name              = "/aws/lambda/${var.lambda_function_name}"
  retention_in_days = var.log_retention_days

  tags = var.tags
}
