# deep-learning

## Status

OK (6/Jul/2025).

## Choose your Image

```SH
aws ec2 describe-images \
  --region us-west-2 \
  --query 'Images[?contains(Name, `Amazon Linux 2023`) && contains(Name, `Deep Learning`)].[ImageId,Name]' \
  --output table
```

## SG

Make sure your security group allows:

SSH (port 22) from your IP

Any other ports (e.g. 8888 for Jupyter)
