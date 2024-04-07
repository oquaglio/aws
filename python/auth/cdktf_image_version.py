import json
import os
import boto3
import argparse

parser = argparse.ArgumentParser(description="Get secrets from AWS Secrets Manager.")
parser.add_argument("--secret-id", required=True, help="Secret ID in AWS Secrets Manager")
args = parser.parse_args()

# The module uses these:
# self.aws_account_credentials_access_key = os.environ["AWS_ACCESS_KEY_ID"]
# self.aws_account_credentials_access_secret_key = os.environ["AWS_SECRET_ACCESS_KEY"]
# self.aws_account_credentials_region = os.environ["AWS_REGION"]

secretsmanager_client = boto3.client(
    "secretsmanager",
    aws_access_key_id=os.environ["AWS_ACCESS_KEY_ID"],
    aws_secret_access_key=os.environ["AWS_SECRET_ACCESS_KEY"],
    aws_session_token=os.environ.get("AWS_SESSION_TOKEN"),  # Required for temporary credentials
    region_name=os.environ["AWS_REGION"],
)

response = secretsmanager_client.get_secret_value(SecretId=args.secret_id)
dms_secrets = json.loads(response["SecretString"])
dms_secrets["dms_endpoints"] = json.loads(dms_secrets["dms_endpoints"])
dms_endpoints = dms_secrets["dms_endpoints"]
print(dms_endpoints)
