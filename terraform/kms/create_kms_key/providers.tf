terraform {

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.0" # Use 6.x series — stable, feature-rich, and widely adopted in 2026
      # You can tighten this later, e.g. "~> 6.28" once you're locked in
    }
  }
}


provider "aws" {
  #region = var.aws_region # We'll define this variable next

  # Optional: useful for tagging consistency across all resources
  default_tags {
    tags = {
      ManagedBy   = "Terraform"
      Project     = "create_kms_key"
      Environment = var.environment # e.g. dev, staging, prod
      Owner       = "Otto"
    }
  }
}

variable "aws_region" {
  description = "AWS Region for all resources"
  type        = string
  default     = "ap-southeast-2" # Sydney — closest & lowest latency for Perth, WA
}

variable "environment" {
  description = "Deployment environment"
  type        = string
  default     = "dev"
}

# outputs.tf

data "aws_region" "current" {}

output "current_aws_region" {
  description = "The AWS region in use"
  value       = data.aws_region.current.name
}
