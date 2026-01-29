variable "aws_region" {
  description = "AWS region for resources"
  type        = string
  default     = "ap-southeast-2"
}

variable "environment" {
  description = "Environment name (e.g., dev, staging, prod)"
  type        = string
  default     = "dev"
}

variable "ecr_repository_name" {
  description = "Name of the ECR repository"
  type        = string
  default     = "lambda-docker-example"
}

variable "lambda_function_name" {
  description = "Name of the Lambda function"
  type        = string
  default     = "docker-lambda-example"
}

variable "image_tag" {
  description = "Docker image tag"
  type        = string
  default     = "latest"
}

variable "image_version" {
  description = "Semantic version for the image (e.g., 1.0.0, 2.1.3)"
  type        = string
  default     = "0.1.0"
}

variable "image_retention_count" {
  description = "Number of images to retain in ECR"
  type        = number
  default     = 5
}

variable "lambda_timeout" {
  description = "Lambda function timeout in seconds"
  type        = number
  default     = 30
}

variable "lambda_memory_size" {
  description = "Lambda function memory size in MB"
  type        = number
  default     = 256
}

variable "log_retention_days" {
  description = "CloudWatch log retention in days"
  type        = number
  default     = 14
}

variable "tags" {
  description = "Tags to apply to resources"
  type        = map(string)
  default = {
    Project   = "lambda-docker-ecr"
    ManagedBy = "terraform"
  }
}
