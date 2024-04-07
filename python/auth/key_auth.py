import boto3
import json
import argparse

# Set up argument parser
parser = argparse.ArgumentParser(description="Get secrets from AWS Secrets Manager.")
parser.add_argument("--access-key", required=True, help="AWS access key ID")
parser.add_argument("--secret-key", required=True, help="AWS secret access key")
parser.add_argument("--region", required=True, help="AWS region")
parser.add_argument("--secret-id", required=True, help="Secret ID in AWS Secrets Manager")

# Parse arguments from the command line
args = parser.parse_args()

# Create a Secrets Manager client using the provided credentials and region
secretsmanager_client = boto3.client(
    "secretsmanager",
    aws_access_key_id=args.access_key,
    aws_secret_access_key=args.secret_key,
    region_name=args.region,
)

# Retrieve the secret value
response = secretsmanager_client.get_secret_value(SecretId=args.secret_id)

# Process the secret
dms_secrets = json.loads(response["SecretString"])
dms_secrets["dms_endpoints"] = json.loads(dms_secrets["dms_endpoints"])
dms_endpoints = dms_secrets["dms_endpoints"]

# Print or use the dms_endpoints as needed
print(dms_endpoints)
