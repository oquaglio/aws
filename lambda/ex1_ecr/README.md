# Lambda with ECR Docker Image - Terraform Example

This Terraform project creates an AWS Lambda function that runs from a Docker container image stored in Amazon ECR.

## Architecture

```
┌─────────────────┐     ┌─────────────────┐     ┌─────────────────┐
│   Dockerfile    │────▶│   ECR Repo      │────▶│   Lambda        │
│   + app.py      │     │   (Image)       │     │   Function      │
└─────────────────┘     └─────────────────┘     └─────────────────┘
```

## Prerequisites

- AWS CLI configured with appropriate credentials
- Terraform >= 1.0
- Docker installed and running

## Project Structure

```
.
├── main.tf           # Main Terraform configuration
├── variables.tf      # Input variables
├── outputs.tf        # Output values
├── versions.tf       # Provider requirements
├── README.md         # This file
└── src/
    ├── Dockerfile    # Lambda container image definition
    └── app.py        # Lambda function code
```

## Usage

1. **Initialize Terraform:**
   ```bash
   terraform init
   ```

2. **Review the plan:**
   ```bash
   terraform plan
   ```

3. **Apply the configuration:**
   ```bash
   terraform apply
   ```

4. **Test the Lambda function:**
   ```bash
   aws lambda invoke \
     --function-name docker-lambda-example \
     --payload '{"key": "value"}' \
     --cli-binary-format raw-in-base64-out \
     response.json

   cat response.json
   ```

## Configuration

Customize the deployment by creating a `terraform.tfvars` file:

```hcl
aws_region           = "ap-southeast-2"
environment          = "dev"
ecr_repository_name  = "my-lambda-repo"
lambda_function_name = "my-lambda-function"
image_tag            = "v1.0.0"
lambda_timeout       = 60
lambda_memory_size   = 512
```

## Variables

| Name | Description | Default |
|------|-------------|---------|
| `aws_region` | AWS region | `ap-southeast-2` |
| `environment` | Environment name | `dev` |
| `ecr_repository_name` | ECR repository name | `lambda-docker-example` |
| `lambda_function_name` | Lambda function name | `docker-lambda-example` |
| `image_tag` | Docker image tag | `latest` |
| `lambda_timeout` | Timeout in seconds | `30` |
| `lambda_memory_size` | Memory in MB | `256` |

## Outputs

| Name | Description |
|------|-------------|
| `ecr_repository_url` | ECR repository URL |
| `lambda_function_arn` | Lambda function ARN |
| `lambda_function_invoke_arn` | Lambda invoke ARN |
| `image_uri` | Full Docker image URI |

## Cleanup

```bash
terraform destroy
```

## Notes

- The Docker image is built and pushed during `terraform apply`
- Image rebuilds are triggered when the Dockerfile or app.py changes
- ECR lifecycle policy keeps only the last 5 images by default
