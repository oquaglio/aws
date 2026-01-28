variable "aws_region" {
  description = "AWS region for resources. Defaults to AWS_REGION or AWS_DEFAULT_REGION env var."
  type        = string
  default     = null
}

variable "project_name" {
  description = "Project name used for resource naming"
  type        = string
  default     = "cross-account-demo"
}

variable "tags" {
  description = "Tags to apply to all resources"
  type        = map(string)
  default = {
    Project     = "cross-account-demo"
    Environment = "demo"
    ManagedBy   = "terraform"
  }
}
