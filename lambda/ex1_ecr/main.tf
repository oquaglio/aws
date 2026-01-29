# Get current AWS account and region
data "aws_caller_identity" "current" {}
data "aws_region" "current" {}

locals {
  account_id = data.aws_caller_identity.current.account_id
  region     = data.aws_region.current.id
  ecr_url    = "${local.account_id}.dkr.ecr.${local.region}.amazonaws.com"

  # Multi-tag strategy: git SHA + timestamp + latest
  # The primary tag used for Lambda is the git SHA for immutable deployments
  image_uri = "${aws_ecr_repository.lambda.repository_url}:${var.image_tag}"
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

# ECR Lifecycle Policy - rolling window with cleanup of unreferenced images
resource "aws_ecr_lifecycle_policy" "lambda" {
  repository = aws_ecr_repository.lambda.name

  policy = jsonencode({
    rules = [
      {
        # Rule 1: Remove untagged images after 1 day
        # These are typically intermediate build layers or failed pushes
        rulePriority = 1
        description  = "Remove untagged images after 1 day"
        selection = {
          tagStatus   = "untagged"
          countType   = "sinceImagePushed"
          countUnit   = "days"
          countNumber = 1
        }
        action = {
          type = "expire"
        }
      },
      {
        # Rule 2: Keep only the last N images with sha- prefix (git commits)
        # This creates the rolling window of deployable images
        rulePriority = 2
        description  = "Keep last ${var.image_retention_count} git SHA tagged images"
        selection = {
          tagStatus     = "tagged"
          tagPrefixList = ["sha-"]
          countType     = "imageCountMoreThan"
          countNumber   = var.image_retention_count
        }
        action = {
          type = "expire"
        }
      },
      {
        # Rule 3: Keep only the last N timestamp-tagged images
        rulePriority = 3
        description  = "Keep last ${var.image_retention_count} timestamp tagged images"
        selection = {
          tagStatus     = "tagged"
          tagPrefixList = ["ts-"]
          countType     = "imageCountMoreThan"
          countNumber   = var.image_retention_count
        }
        action = {
          type = "expire"
        }
      },
      {
        # Rule 4: Keep last N semver releases (v* tags)
        # These are production releases and should be retained longer
        rulePriority = 4
        description  = "Keep last ${var.image_retention_count * 2} semver releases"
        selection = {
          tagStatus     = "tagged"
          tagPrefixList = ["v"]
          countType     = "imageCountMoreThan"
          countNumber   = var.image_retention_count * 2
        }
        action = {
          type = "expire"
        }
      },
      {
        # Rule 5: Expire old images that don't match protected patterns
        # Catches any other tagged images older than 30 days
        rulePriority = 5
        description  = "Expire other tagged images older than 30 days"
        selection = {
          tagStatus     = "tagged"
          tagPrefixList = ["dev-", "test-", "build-"]
          countType     = "sinceImagePushed"
          countUnit     = "days"
          countNumber   = 30
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
    image_version   = var.image_version
  }

  provisioner "local-exec" {
    command = <<-EOT
      set -e

      # Generate tags
      REPO_URL="${aws_ecr_repository.lambda.repository_url}"
      GIT_SHA=$(git rev-parse --short HEAD 2>/dev/null || echo "no-git")
      TIMESTAMP=$(date -u +"%Y%m%d-%H%M%S")
      PRIMARY_TAG="${var.image_tag}"
      VERSION="v${var.image_version}"

      echo "Building with tags: $PRIMARY_TAG, $VERSION, sha-$GIT_SHA, ts-$TIMESTAMP, latest"

      # Login to ECR
      aws ecr get-login-password --region ${local.region} | docker login --username AWS --password-stdin ${local.ecr_url}

      # Build the Docker image with primary tag
      docker build -t "$REPO_URL:$PRIMARY_TAG" ${path.module}/src

      # Apply additional tags
      docker tag "$REPO_URL:$PRIMARY_TAG" "$REPO_URL:$VERSION"
      docker tag "$REPO_URL:$PRIMARY_TAG" "$REPO_URL:sha-$GIT_SHA"
      docker tag "$REPO_URL:$PRIMARY_TAG" "$REPO_URL:ts-$TIMESTAMP"
      docker tag "$REPO_URL:$PRIMARY_TAG" "$REPO_URL:latest"

      # Push all tags
      docker push "$REPO_URL:$PRIMARY_TAG"
      docker push "$REPO_URL:$VERSION"
      docker push "$REPO_URL:sha-$GIT_SHA"
      docker push "$REPO_URL:ts-$TIMESTAMP"
      docker push "$REPO_URL:latest"

      echo "Successfully pushed image with tags: $PRIMARY_TAG, $VERSION, sha-$GIT_SHA, ts-$TIMESTAMP, latest"
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
