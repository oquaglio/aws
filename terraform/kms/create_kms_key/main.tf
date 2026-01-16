data "aws_caller_identity" "current" {}

output "aws_caller_identity" {
  value = data.aws_caller_identity.current
}

resource "aws_kms_key" "example" {
  description              = "My symmetric encryption key"
  customer_master_key_spec = "SYMMETRIC_DEFAULT" # Default symmetric key type (AES-256)
  key_usage                = "ENCRYPT_DECRYPT"   # For encryption/decryption
  enable_key_rotation      = true                # Enables annual auto-rotation
  deletion_window_in_days  = 10                  # Wait 10 days before permanent deletion
  is_enabled               = true

  policy = jsonencode({
    Version = "2012-10-17"
    Id      = "key-default-policy"
    Statement = [
      {
        Sid    = "Enable IAM User Permissions"
        Effect = "Allow"
        Principal = {
          AWS = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:root"
        }
        Action   = "kms:*"
        Resource = "*"
      }
    ]
  })

  tags = {
    Name = "example-key"
  }
}

# Alias points the alias to your key's ID. Allows referencing the key as "alias/my-app-key".
resource "aws_kms_alias" "example_alias" {
  name          = "alias/my-app-key" # Must start with 'alias/'
  target_key_id = aws_kms_key.example.key_id
}

# IAM #########################################################################


# Grants an IAM role (e.g., for EC2 instances) permission to encrypt/decrypt
# using the key, with an optional context check. Grants are revocable and don't
# alter the policy. Use retire_on_delete = true if you want the grant removed
# when destroying the resource.
resource "aws_iam_role" "example_role" {
  name = "example-role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "ec2.amazonaws.com"
        }
      }
    ]
  })
}

resource "aws_kms_grant" "example_grant" {
  name              = "my-grant"
  key_id            = aws_kms_key.example.key_id
  grantee_principal = aws_iam_role.example_role.arn
  operations        = ["Encrypt", "Decrypt", "GenerateDataKey"]

  # Optional: Add constraints, e.g., encryption context
  constraints {
    encryption_context_equals = {
      Department = "Finance"
    }
  }

  # Optional: Retiring principal for revoking the grant
  retiring_principal = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:root"
}


# OUTPUTS #####################################################################

output "key_arn" {
  value = aws_kms_key.example.arn
}
output "key_id" {
  value = aws_kms_key.example.key_id
}

output "alias_name" {
  value = aws_kms_alias.example_alias.name
}
