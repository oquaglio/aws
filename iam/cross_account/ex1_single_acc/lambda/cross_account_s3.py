"""
Lambda function demonstrating cross-account S3 access via role assumption.

This function:
1. Assumes a role in the target account using STS
2. Uses the temporary credentials to access an S3 bucket in the target account
3. Performs read/write operations on the bucket
"""

import json
import os
import boto3
from botocore.exceptions import ClientError


def get_cross_account_s3_client():
    """
    Assume the cross-account role and return an S3 client with temporary credentials.
    """
    role_arn = os.environ["TARGET_ROLE_ARN"]
    external_id = os.environ["EXTERNAL_ID"]

    # Create STS client to assume the cross-account role
    sts_client = boto3.client("sts")

    # Assume the role in the target account
    assumed_role = sts_client.assume_role(
        RoleArn=role_arn,
        RoleSessionName="CrossAccountS3Access",
        ExternalId=external_id,
        DurationSeconds=900  # 15 minutes
    )

    # Extract temporary credentials
    credentials = assumed_role["Credentials"]

    # Create S3 client with the assumed role credentials
    s3_client = boto3.client(
        "s3",
        aws_access_key_id=credentials["AccessKeyId"],
        aws_secret_access_key=credentials["SecretAccessKey"],
        aws_session_token=credentials["SessionToken"]
    )

    return s3_client


def lambda_handler(event, context):
    """
    Main Lambda handler demonstrating cross-account S3 operations.

    Supported operations (via event["operation"]):
    - list: List objects in the bucket
    - read: Read an object (requires event["key"])
    - write: Write an object (requires event["key"] and event["content"])
    """
    bucket_name = os.environ["TARGET_BUCKET_NAME"]
    operation = event.get("operation", "list")

    results = {
        "operation": operation,
        "bucket": bucket_name,
        "status": "success"
    }

    try:
        # Get S3 client with cross-account credentials
        s3_client = get_cross_account_s3_client()

        if operation == "list":
            # List objects in the bucket
            response = s3_client.list_objects_v2(
                Bucket=bucket_name,
                MaxKeys=100
            )
            objects = [obj["Key"] for obj in response.get("Contents", [])]
            results["objects"] = objects
            results["count"] = len(objects)

        elif operation == "read":
            # Read an object from the bucket
            key = event.get("key")
            if not key:
                raise ValueError("Missing 'key' in event for read operation")

            response = s3_client.get_object(Bucket=bucket_name, Key=key)
            content = response["Body"].read().decode("utf-8")
            results["key"] = key
            results["content"] = content

        elif operation == "write":
            # Write an object to the bucket
            key = event.get("key")
            content = event.get("content")
            if not key or content is None:
                raise ValueError("Missing 'key' or 'content' in event for write operation")

            s3_client.put_object(
                Bucket=bucket_name,
                Key=key,
                Body=content.encode("utf-8")
            )
            results["key"] = key
            results["message"] = f"Successfully wrote to {key}"

        else:
            results["status"] = "error"
            results["error"] = f"Unknown operation: {operation}"

    except ClientError as e:
        results["status"] = "error"
        results["error"] = str(e)
        results["error_code"] = e.response["Error"]["Code"]

    except Exception as e:
        results["status"] = "error"
        results["error"] = str(e)

    return {
        "statusCode": 200 if results["status"] == "success" else 500,
        "body": json.dumps(results, indent=2)
    }
