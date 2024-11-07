# AWS Wazuh Integration Script

This project provides an automated script using Terraform and Bash to integrate AWS logs (specifically from Amazon CloudTrail and Amazon VPC Flow Logs) with Wazuh. The setup includes dependency installation, S3 bucket configuration, IAM setup, AWS CloudTrail, and VPC flow logs configuration.

## Prerequisites

You will need:
- AWS account with permissions to create S3 buckets, IAM users, and CloudTrail/VPC configurations.
- **Bash** and **Terraform** installed.

### Dependency Installation

The script will check and install dependencies if they are missing:
```bash
apt-get update && apt-get install -y python3 python3-pip
pip3 install --upgrade pip --break-system-packages
pip3 install --break-system-packages boto3==1.34.135 pyarrow==14.0.1 numpy==1.26.0
```

## Project Structure

The project has the following structure:
```plaintext
aws-wazuh-integration/
├── main.tf                # Terraform script with all configurations
├── variables.tf           # Variables for customization
├── iam_policy.json        # IAM Policy for S3 access
└── setup.sh               # Bash script wizard
```

## Step-by-Step Guide

### Step 1: Run the Setup Script

Use the `setup.sh` script to guide through the configuration process.

```bash
chmod +x setup.sh
./setup.sh
```

This script will:
1. Check and install dependencies if necessary.
2. Prompt whether to use an existing S3 bucket or create a new one.
3. Provide manual instructions for IAM setup if credentials are unavailable.
4. Configure AWS credentials in `/root/.aws/credentials` for the Wazuh integration.

### Step 2: Configure Terraform Variables

Edit `variables.tf` to set the following parameters based on your requirements:

- `aws_region`: The AWS region.
- `bucket_name`: Name of the S3 bucket for logs.
- `iam_group_name`: IAM group name for S3 access.
- `iam_role_arn`: IAM Role ARN for VPC flow logs.
- `vpc_id`: VPC ID for which flow logs will be enabled.

### Step 3: Run Terraform

After completing the setup wizard, initialize and apply Terraform to provision resources.

```bash
terraform init
terraform apply -var="bucket_name=<your_bucket_name>" -auto-approve
```

## Configuration Details

- **Amazon CloudTrail**: Configures CloudTrail to log management events to the S3 bucket with SSE-KMS encryption.
- **Amazon VPC Flow Logs**: Configures flow logs for a specified VPC, sending logs to the S3 bucket.

## Notes

- **IAM Policy**: Located in `iam_policy.json`, this policy grants the necessary S3 access to the IAM user group.
- **Delays**: The script includes sleep delays between steps to provide users time to follow the process.

---

## Sample `iam_policy.json`

The IAM policy file (`iam_policy.json`) grants S3 access to the bucket configured for log storage.

```json
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Sid": "GetS3Logs",
            "Effect": "Allow",
            "Action": [
                "s3:GetObject",
                "s3:ListBucket"
            ],
            "Resource": [
                "arn:aws:s3:::${var.bucket_name}/*",
                "arn:aws:s3:::${var.bucket_name}"
            ]
        }
    ]
}
```

This policy should be attached to the IAM user group created in the setup.

---

## Summary

This setup provides an efficient way to monitor AWS logs from CloudTrail and VPC flow logs with Wazuh, allowing for centralized log management and enhanced security visibility.

For further customization, modify the Terraform files and `setup.sh` script according to your organization's requirements.

---

## License

This project is licensed under the MIT License.