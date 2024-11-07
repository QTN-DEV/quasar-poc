provider "aws" {
  region  = var.aws_region
  profile = "wazuh-profile"
}

# S3 Bucket for logs
resource "aws_s3_bucket" "wazuh_log_bucket" {
  count  = var.use_existing_bucket ? 0 : 1
  bucket = var.bucket_name
  force_destroy = true
}

# Server-Side Encryption for S3 Bucket
resource "aws_s3_bucket_server_side_encryption_configuration" "wazuh_log_bucket_encryption" {
  count    = var.use_existing_bucket ? 0 : 1
  bucket   = aws_s3_bucket.wazuh_log_bucket[count.index].bucket

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

# KMS Key for CloudTrail encryption
resource "aws_kms_key" "cloudtrail_kms" {
  description = "KMS key for encrypting CloudTrail logs"
}

# IAM Policy for accessing S3 bucket
resource "aws_iam_policy" "s3_log_access" {
  name   = "WazuhS3LogAccess"
  path   = "/"
  policy = file("iam_policy.json")
}

# Attach policy to IAM group
resource "aws_iam_group_policy_attachment" "attach_policy" {
  group      = var.iam_group_name
  policy_arn = aws_iam_policy.s3_log_access.arn
}

# CloudTrail Configuration
resource "aws_cloudtrail" "wazuh_cloudtrail" {
  name                          = "wazuh-cloudtrail"
  s3_bucket_name                = aws_s3_bucket.wazuh_log_bucket[count.index].bucket
  enable_log_file_validation    = true
  kms_key_id                    = aws_kms_key.cloudtrail_kms.arn
  is_multi_region_trail         = true
  include_global_service_events = true

  event_selector {
    read_write_type           = "All"
    include_management_events = true
    data_resource {
      type   = "AWS::S3::Object"
      values = ["arn:aws:s3:::${aws_s3_bucket.wazuh_log_bucket[count.index].bucket}/*"]
    }
  }
}

# VPC Flow Logs Configuration
resource "aws_flow_log" "vpc_flow_log" {
  log_destination = aws_s3_bucket.wazuh_log_bucket[count.index].arn
  iam_role_arn    = var.iam_role_arn
  vpc_id          = var.vpc_id
  traffic_type    = "ALL"
}