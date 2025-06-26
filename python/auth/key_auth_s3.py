import argparse

import boto3

# Set up argument parser
parser = argparse.ArgumentParser(description="List S3 buckets using AWS credentials.")
parser.add_argument("--access-key", required=True, help="AWS access key ID")
parser.add_argument("--secret-key", required=True, help="AWS secret access key")
parser.add_argument("--region", required=True, help="AWS region")

# Parse arguments from the command line
args = parser.parse_args()

# Create an S3 client
s3_client = boto3.client(
    "s3",
    aws_access_key_id=args.access_key,
    aws_secret_access_key=args.secret_key,
    region_name=args.region,
)

# List all S3 buckets
response = s3_client.list_buckets()

# Print bucket names
print("S3 Buckets:")
for bucket in response.get("Buckets", []):
    print(f" - {bucket['Name']}")
