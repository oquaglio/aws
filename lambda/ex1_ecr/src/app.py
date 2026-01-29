import json
import os


def handler(event, context):
    """
    Lambda handler function.
    """
    print(f"Received event: {json.dumps(event)}")

    return {
        "statusCode": 200,
        "body": json.dumps({
            "message": "Hello from Lambda running in a Docker container!",
            "event": event,
            "environment": os.environ.get("ENVIRONMENT", "unknown")
        })
    }
