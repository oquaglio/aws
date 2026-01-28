# create_kms_key

## Prereqs

Set AWS env vars.


## Describe key
```sh
aws kms describe-key --key-id alias/my-app-key
```

## Test the Key

### Encrypt

```sh
aws kms encrypt \
  --key-id alias/my-app-key \
  --plaintext fileb://<(echo -n "hello") \
  --output text \
  --query CiphertextBlob
```
- echo -n "hello" → outputs "hello" without trailing newline (good for exact strings)
- fileb://<(...) → process substitution; feeds the output as a "file" to the CLI
- --output text --query CiphertextBlob → gets just the base64-encoded ciphertext (clean output)

Or similalrly:
```sh
aws kms encrypt \
  --key-id alias/my-app-key \
  --plaintext $(echo -n "hello" | base64) \
  --output text \
  --query CiphertextBlob
```

### Full Test Round-Trip (Encrypt + Decrypt)

Encrypt:
```sh
ciphertext=$(aws kms encrypt \
  --key-id alias/my-app-key \
  --plaintext fileb://<(echo -n "hello") \
  --output text \
  --query CiphertextBlob)
echo "Encrypted (base64): $ciphertext"
```

Decrypt back to original:
```sh
decrypted=$(aws kms decrypt \
  --ciphertext-blob fileb://<(echo "$ciphertext" | base64 --decode) \
  --output text \
  --query Plaintext | base64 --decode)
echo "Decrypted: $decrypted"
```
Should print: Decrypted: hello
