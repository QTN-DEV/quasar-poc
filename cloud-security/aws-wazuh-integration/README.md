# AWS CloudTrail and VPC Flow Logs Integration with Wazuh

This document outlines the steps and necessary IAM policies for setting up AWS CloudTrail and VPC Flow Logs integration with Wazuh, using Terraform and a bash script to automate resource creation and configuration.

---

## Prerequisites

- **AWS Account** with permissions to create IAM roles, S3 buckets, KMS keys, and enable CloudTrail and VPC Flow Logs.
- **Terraform** and **Bash** installed on your local machine or CI/CD environment.

---

## IAM Policies Required

To ensure `quasar-user` or any IAM user has the necessary permissions, the following IAM policies need to be created and attached:

### 1. CloudTrail and KMS Permissions

CloudTrail requires access to an S3 bucket for log storage and a KMS key for encryption. Create a policy that includes the following actions:

```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "s3:PutObject",
        "s3:GetBucketAcl"
      ],
      "Resource": [
        "arn:aws:s3:::<your-bucket-name>/*",
        "arn:aws:s3:::<your-bucket-name>"
      ]
    },
    {
      "Effect": "Allow",
      "Action": [
        "kms:Encrypt",
        "kms:Decrypt",
        "kms:ReEncrypt*",
        "kms:GenerateDataKey*",
        "kms:DescribeKey"
      ],
      "Resource": "*",
      "Condition": {
        "StringEquals": {
          "aws:SourceAccount": "<your-account-id>"
        },
        "ArnLike": {
          "aws:SourceArn": "arn:aws:cloudtrail:<region>:<your-account-id>:trail/*"
        }
      }
    }
  ]
}
```

### 2. VPC Flow Logs Permissions

To enable VPC Flow Logs, the following policy is required:

```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "ec2:CreateFlowLogs",
        "ec2:DescribeFlowLogs",
        "ec2:DeleteFlowLogs"
      ],
      "Resource": "*"
    }
  ]
}
```

### 3. CloudWatch Log Delivery Permissions

To create and manage CloudWatch Logs delivery configurations, use the following policy:

```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "logs:CreateLogDelivery",
        "logs:GetLogDelivery",
        "logs:DeleteLogDelivery",
        "logs:ListLogDeliveries",
        "logs:UpdateLogDelivery"
      ],
      "Resource": "*"
    }
  ]
}
```

---

## Terraform Configuration

Here’s the complete `main.tf` configuration for setting up AWS resources:

```hcl
provider "aws" {
  region  = var.aws_region
  profile = "wazuh-profile"
}

# Generate a random suffix for unique S3 bucket naming
resource "random_id" "id" {
  byte_length = 4
}

# S3 Bucket for logs
resource "aws_s3_bucket" "wazuh_log_bucket" {
  bucket         = "${var.bucket_name}-${random_id.id.hex}"
  force_destroy  = true
}

# Separate encryption configuration for the S3 bucket
resource "aws_s3_bucket_server_side_encryption_configuration" "wazuh_bucket_encryption" {
  bucket = aws_s3_bucket.wazuh_log_bucket.bucket

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

# S3 Bucket Policy for CloudTrail
resource "aws_s3_bucket_policy" "cloudtrail_bucket_policy" {
  bucket = aws_s3_bucket.wazuh_log_bucket.id

  policy = jsonencode({
    "Version": "2012-10-17",
    "Statement": [
      {
        "Effect": "Allow",
        "Principal": {
          "Service": "cloudtrail.amazonaws.com"
        },
        "Action": "s3:PutObject",
        "Resource": [
          "arn:aws:s3:::${aws_s3_bucket.wazuh_log_bucket.bucket}/*"
        ],
        "Condition": {
          "StringEquals": {
            "s3:x-amz-acl": "bucket-owner-full-control",
            "aws:SourceAccount": "${data.aws_caller_identity.current.account_id}"
          },
          "ArnLike": {
            "aws:SourceArn": "arn:aws:cloudtrail:${var.aws_region}:${data.aws_caller_identity.current.account_id}:trail/*"
          }
        }
      },
      {
        "Effect": "Allow",
        "Principal": {
          "Service": "cloudtrail.amazonaws.com"
        },
        "Action": "s3:GetBucketAcl",
        "Resource": "arn:aws:s3:::${aws_s3_bucket.wazuh_log_bucket.bucket}"
      }
    ]
  })
}

# Retrieve account information for KMS policy
data "aws_caller_identity" "current" {}

# KMS Key for CloudTrail encryption
resource "aws_kms_key" "cloudtrail_kms" {
  description = "KMS key for encrypting CloudTrail logs"

  policy = jsonencode({
    "Version": "2012-10-17",
    "Statement": [
      {
        "Effect": "Allow",
        "Principal": {
          "Service": "cloudtrail.amazonaws.com"
        },
        "Action": [
          "kms:Encrypt",
          "kms:Decrypt",
          "kms:ReEncrypt*",
          "kms:GenerateDataKey*",
          "kms:DescribeKey"
        ],
        "Resource": "*",
        "Condition": {
          "StringEquals": {
            "aws:SourceAccount": "${data.aws_caller_identity.current.account_id}"
          },
          "ArnLike": {
            "aws:SourceArn": "arn:aws:cloudtrail:${var.aws_region}:${data.aws_caller_identity.current.account_id}:trail/*"
          }
        }
      },
      {
        "Effect": "Allow",
        "Principal": {
          "AWS": "${data.aws_caller_identity.current.arn}"
        },
        "Action": "kms:*",
        "Resource": "*"
      }
    ]
  })
}

# IAM Role for VPC Flow Logs
resource "aws_iam_role" "vpc_flow_log_role" {
  name = "VpcFlowLogRole"
  assume_role_policy = jsonencode({
    "Version": "2012-10-17",
    "Statement": [
      {
        "Action": "sts:AssumeRole",
        "Effect": "Allow",
        "Principal": {
          "Service": "vpc-flow-logs.amazonaws.com"
        }
      }
    ]
  })
}

# CloudTrail Configuration
resource "aws_cloudtrail" "wazuh_cloudtrail" {
  name                          = "wazuh-cloudtrail"
  s3_bucket_name                = aws_s3_bucket.wazuh_log_bucket.bucket
  enable_log_file_validation    = true
  kms_key_id                    = aws_kms_key.cloudtrail_kms.arn
  is_multi_region_trail         = true
  include_global_service_events = true

  event_selector {
    read_write_type           = "All"
    include_management_events = true
    data_resource {
      type   = "AWS::S3::Object"
      values = ["arn:aws:s3:::${aws_s3_bucket.wazuh_log_bucket.bucket}/*"]
    }
  }
}

# VPC Flow Logs Configuration
resource "aws_flow_log" "vpc_flow_log" {
  log_destination      = "arn:aws:s3:::${aws_s3_bucket.wazuh_log_bucket.bucket}"
  log_destination_type = "s3"  
  vpc_id               = "vpc-xxxxxx"  # Replace with your VPC ID
  traffic_type         = "ALL"
}
```

---

## Running the Bash Script

To automate the setup process, use the provided Bash script. This script will:
- Install necessary dependencies (such as `awscli` and `python3`).
- Set up Terraform configuration files and initialize Terraform.
- Prompt for user input on existing resources or guide through resource creation.

### Steps

1. **Give execution permissions** to the script:
   ```bash
   chmod +x setup.sh
   ```

2. **Run the script**:
   ```bash
   ./setup.sh
   ```

3. **Follow the prompts** to choose between creating a new S3 bucket or using an existing one, set IAM roles, and configure CloudTrail and VPC Flow Logs.

---

## Summary

1. **Attach IAM policies** to `quasar-user` or another IAM user to allow `ec2:CreateFlowLogs`, CloudTrail and S3 permissions, and KMS key access.
2. **Deploy resources** with Terraform, which sets up S3 bucket, KMS encryption, IAM roles, CloudTrail, and VPC Flow Logs.
3. **Run the Bash script** to automate deployment and follow prompts for configuration.

---