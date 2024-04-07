import os
import boto3
import json
import argparse

parser = argparse.ArgumentParser(description="Get secrets from AWS Secrets Manager.")

parser.add_argument("--region", required=True, help="AWS region")
parser.add_argument("--secret-id", required=True, help="Secret ID in AWS Secrets Manager")
args = parser.parse_args()

print("Access Key:", os.environ.get("AWS_ACCESS_KEY_ID"))
print("Secret Access Key:", os.environ.get("AWS_SECRET_ACCESS_KEY"))
print("Session Token:", os.environ.get("AWS_SESSION_TOKEN"))

session = boto3.Session(
    aws_access_key_id=os.environ.get("AWS_ACCESS_KEY_ID"),
    aws_secret_access_key=os.environ.get("AWS_SECRET_ACCESS_KEY"),
    aws_session_token=os.environ.get("AWS_SESSION_TOKEN"),  # Required for temporary credentials
)

client = session.client("secretsmanager", region_name=args.region)

try:
    response = client.get_secret_value(SecretId=args.secret_id)
    print(response)
except client.exceptions.ClientError as e:
    print(e)
