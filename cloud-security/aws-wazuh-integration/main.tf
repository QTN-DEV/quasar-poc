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

# Attach policy to allow writing to S3 for VPC Flow Logs
resource "aws_iam_role_policy" "vpc_flow_log_policy" {
  name   = "VpcFlowLogToS3Policy"
  role   = aws_iam_role.vpc_flow_log_role.id
  policy = jsonencode({
    "Version": "2012-10-17",
    "Statement": [
      {
        "Effect": "Allow",
        "Action": [
          "s3:PutObject"
        ],
        "Resource": [
          "arn:aws:s3:::${aws_s3_bucket.wazuh_log_bucket.bucket}/*"
        ]
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
  log_destination_type = "s3"  # Specify that this is an S3 bucket destination
  vpc_id               = "vpc-045a4aeccfd298ab0"  # Replace with your VPC ID
  traffic_type         = "ALL"
}
