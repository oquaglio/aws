# ec2

## SGs

Add an inbound rule to the SG associated with the instance:
Type:      SSH
Protocol:  TCP
Port:      22
Source:    Your IP (or 0.0.0.0/0 for testing - all ips)

Add any other ports as required. E.g. Jupyter

## Manual Step: Create a Key Pair

Create under AWS Console -> EC2 -> Key Pairs

My naming conv:
ec2-key-pair

## SSH

```SH
ssh -i ~/.ssh/your-key.pem ec2-user@<public-ip>
```

Get Public IP:
```SH
aws ec2 describe-instances \
  --filters "Name=tag:Name,Values=dl-x86-gpu" \
  --query "Reservations[*].Instances[*].PublicIpAddress" \
  --output text
```

Get all Running:
```SH
aws ec2 describe-instances \
  --filters "Name=instance-state-name,Values=running" \
  --query "Reservations[*].Instances[*].[InstanceId,PublicIpAddress]" \
  --output table
```

Username:
| AMI Type                          | SSH Username        |
| --------------------------------- | ------------------- |
| Amazon Linux (AL2, AL2023)        | `ec2-user`          |
| Ubuntu                            | `ubuntu`            |
| Debian                            | `admin` or `debian` |
| RHEL                              | `ec2-user`          |
| CentOS                            | `centos`            |
| Deep Learning AMIs (Amazon Linux) | `ec2-user`          |
| Deep Learning AMIs (Ubuntu)       | `ubuntu`            |

