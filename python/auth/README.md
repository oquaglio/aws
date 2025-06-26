# AWS Auth

Python auth examples.

## Set Vars

AWS_PROFILE="aws2"

export AWS_ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text --profile "$AWS_PROFILE")
export AWS_ACCESS_KEY_ID=$(aws configure get aws_access_key_id --profile "$AWS_PROFILE")
export AWS_SECRET_ACCESS_KEY=$(aws configure get aws_secret_access_key --profile "$AWS_PROFILE")
export AWS_REGION=$(aws configure get region --profile "$AWS_PROFILE")

## Invoke

```SH
python key_auth.py --access-key $AWS_ACCESS_KEY_ID --secret-key $AWS_SECRET_ACCESS_KEY --region $AWS_REGION --secret-id your_secret_id
```

```SH
python key_auth_s3.py --access-key $AWS_ACCESS_KEY_ID --secret-key $AWS_SECRET_ACCESS_KEY --region $AWS_REGION
```

Works ok:
```SH
python key_auth_2.py --region $AWS_REGION --secret-id your_secret_id
```

```SH
python cdktf_image_version.py --secret-id your_secret_id
```
