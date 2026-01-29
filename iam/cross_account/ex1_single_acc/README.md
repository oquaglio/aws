# AWS Cross-Account Role Assumption Demo

This Terraform project demonstrates the AWS cross-account role assumption pattern using a single AWS account. The pattern shown here is identical to what you would use in a real multi-account setup.

## Overview

Cross-account role assumption allows resources in one AWS account (source) to access resources in another AWS account (target) by assuming an IAM role. This is a fundamental pattern for:

- Multi-account AWS architectures
- Centralized logging and monitoring
- Shared services across accounts
- Data pipelines spanning multiple accounts

## Architecture

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                            AWS ACCOUNT                                      │
│                                                                             │
│  "Source Account" Resources          "Target Account" Resources             │
│  ─────────────────────────          ──────────────────────────              │
│                                                                             │
│  ┌─────────────────────────┐        ┌─────────────────────────┐            │
│  │     Lambda Function     │        │   Cross-Account Role    │            │
│  │                         │        │                         │            │
│  │  1. Invoked with        │        │  - Trust policy allows  │            │
│  │     operation request   │        │    Lambda exec role     │            │
│  │                         │        │  - Has S3 permissions   │            │
│  │  2. Calls STS           │        │  - Requires ExternalId  │            │
│  │     AssumeRole ─────────┼────────▶                         │            │
│  │                         │        └───────────┬─────────────┘            │
│  │  3. Gets temporary      │                    │                          │
│  │     credentials         │                    │ Grants access            │
│  │                         │                    ▼                          │
│  │  4. Uses credentials    │        ┌─────────────────────────┐            │
│  │     to access S3  ──────┼────────▶      S3 Bucket          │            │
│  └─────────────────────────┘        │                         │            │
│              │                      │  - Bucket policy allows │            │
│              │                      │    cross-account role   │            │
│  ┌───────────▼─────────────┐        │  - Stores demo objects  │            │
│  │  Lambda Execution Role  │        └─────────────────────────┘            │
│  │                         │                                               │
│  │  - Trusted by Lambda    │                                               │
│  │  - Has sts:AssumeRole   │                                               │
│  │    permission           │                                               │
│  └─────────────────────────┘                                               │
└─────────────────────────────────────────────────────────────────────────────┘
```

## How It Works

### Step 1: Lambda Invocation
The Lambda function is invoked with an operation (list, read, or write).

### Step 2: Role Assumption
The Lambda uses its execution role to call `sts:AssumeRole`, requesting temporary credentials for the cross-account role. An External ID is required for additional security.

```python
assumed_role = sts_client.assume_role(
    RoleArn=role_arn,
    RoleSessionName="CrossAccountS3Access",
    ExternalId=external_id,
    DurationSeconds=900
)
```

### Step 3: Temporary Credentials
STS returns temporary credentials (access key, secret key, session token) valid for the specified duration.

### Step 4: S3 Access
The Lambda creates a new S3 client using the temporary credentials and performs operations on the bucket.

## Components

### IAM Roles

| Role | Purpose | Trust Policy |
|------|---------|--------------|
| `lambda-execution-role` | Attached to Lambda, allows it to run and assume the target role | Trusts `lambda.amazonaws.com` |
| `cross-account-s3-role` | The role that grants S3 access, assumed by Lambda | Trusts the Lambda execution role + requires External ID |

### IAM Policies

| Policy | Attached To | Permissions |
|--------|-------------|-------------|
| Lambda Logging | Lambda execution role | CloudWatch Logs write |
| Assume Role | Lambda execution role | `sts:AssumeRole` on cross-account role |
| S3 Access | Cross-account role | S3 read/write on target bucket |

### S3 Bucket Policy

The bucket policy explicitly allows the cross-account role to perform S3 operations. This is required in addition to the IAM policy because S3 uses both identity-based and resource-based policies.

## Usage

### Prerequisites

- Terraform >= 1.0
- AWS CLI configured with appropriate credentials
- An AWS account

### Deployment

1. Copy the example variables file:
   ```bash
   cp terraform.tfvars.example terraform.tfvars
   ```

2. Edit `terraform.tfvars` with your AWS account ID:
   ```hcl
   account_id   = "123456789012"
   aws_region   = "us-east-1"
   project_name = "cross-account-demo"
   ```

3. Initialize and apply:
   ```bash
   terraform init
   terraform plan
   terraform apply
   ```

### Testing

After deployment, test the Lambda function:

```bash
# List objects in the bucket
aws lambda invoke \
  --function-name cross-account-demo-cross-account-s3 \
  --payload '{"operation": "list"}' \
  --cli-binary-format raw-in-base64-out \
  response.json && cat response.json

# Read an object
aws lambda invoke \
  --function-name cross-account-demo-cross-account-s3 \
  --payload '{"operation": "read", "key": "sample/hello.txt"}' \
  --cli-binary-format raw-in-base64-out \
  response.json && cat response.json

# Write an object
aws lambda invoke \
  --function-name cross-account-demo-cross-account-s3 \
  --payload '{"operation": "write", "key": "test/my-file.txt", "content": "Hello!"}' \
  --cli-binary-format raw-in-base64-out \
  response.json && cat response.json
```

## Adapting for Real Cross-Account Use

To use this pattern across actual separate AWS accounts:

### 1. Split the Terraform Configuration

Create two separate Terraform configurations:

**Source Account (Account A):**
- Lambda function
- Lambda execution role
- Policy allowing `sts:AssumeRole` on the target account role

**Target Account (Account B):**
- S3 bucket and bucket policy
- Cross-account role with trust policy

### 2. Update Trust Policy

In the target account's cross-account role, update the trust policy principal:

```hcl
Principal = {
  AWS = "arn:aws:iam::SOURCE_ACCOUNT_ID:role/lambda-execution-role"
}
```

### 3. Use Separate Providers

```hcl
provider "aws" {
  alias   = "source"
  region  = "us-east-1"
  profile = "source-account-profile"
}

provider "aws" {
  alias   = "target"
  region  = "us-east-1"
  profile = "target-account-profile"
}
```

## Security Considerations

### External ID
The External ID provides protection against the "confused deputy" problem. Always use External IDs when setting up cross-account access for third parties.

### Principle of Least Privilege
- The cross-account role only has permissions for the specific S3 bucket
- The Lambda execution role can only assume the specific cross-account role
- Temporary credentials have a short duration (15 minutes)

### Bucket Policy + IAM Policy
Both are required for cross-account S3 access:
- IAM policy on the role grants the role permission to perform actions
- Bucket policy grants the role permission to access the specific bucket

## Cleanup

```bash
terraform destroy
```

## Files

| File | Description |
|------|-------------|
| `main.tf` | Provider configuration |
| `variables.tf` | Input variables |
| `iam.tf` | IAM roles and policies |
| `s3.tf` | S3 bucket and bucket policy |
| `lambda.tf` | Lambda function configuration |
| `lambda/cross_account_s3.py` | Lambda function code |
| `outputs.tf` | Output values and test commands |


## Cleanup
```sh
ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text) && \
aws s3api delete-objects --bucket cross-account-demo-bucket-${ACCOUNT_ID} \
  --delete "$(aws s3api list-object-versions --bucket cross-account-demo-bucket-${ACCOUNT_ID} --query '{Objects: Versions[].{Key:Key,VersionId:VersionId}}' --output json)"
```

