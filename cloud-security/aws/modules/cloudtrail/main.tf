# S3 Bucket for CloudTrail logs
resource "aws_s3_bucket" "cloudtrail_bucket" {
  bucket = var.bucket_name

  lifecycle {
    prevent_destroy = true
  }

  tags = {
    "Name"        = "CloudTrail-Logs"
    "Environment" = var.environment
  }
}

# CloudTrail Trail Configuration
resource "aws_cloudtrail" "cloudtrail" {
  name                          = "WazuhTrail"
  s3_bucket_name                = aws_s3_bucket.cloudtrail_bucket.bucket
  s3_key_prefix                 = var.log_prefix
  is_multi_region_trail         = true
  enable_log_file_validation    = true

  # Optional KMS encryption if KMS key is provided
  dynamic "kms_key_id" {
    for_each = var.kms_key_id != null ? [var.kms_key_id] : []
    content {
      kms_key_id = kms_key_id.value
    }
  }

  tags = {
    "Name"        = "CloudTrail-Wazuh"
    "Environment" = var.environment
  }
}

# IAM Policy for Read-Only Access
resource "aws_iam_policy" "cloudtrail_read_policy" {
  name        = "CloudTrailReadPolicy"
  description = "IAM policy for read-only access to CloudTrail logs in S3"

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect   = "Allow",
        Action   = ["s3:GetObject", "s3:ListBucket"],
        Resource = [
          "arn:aws:s3:::${aws_s3_bucket.cloudtrail_bucket.bucket}/*",
          "arn:aws:s3:::${aws_s3_bucket.cloudtrail_bucket.bucket}"
        ]
      }
    ]
  })
}

# Optional IAM Policy for Delete Access if enabled
resource "aws_iam_policy" "cloudtrail_delete_policy" {
  count = var.enable_delete_permission ? 1 : 0
  name  = "CloudTrailDeletePolicy"

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect   = "Allow",
        Action   = ["s3:GetObject", "s3:ListBucket", "s3:DeleteObject"],
        Resource = [
          "arn:aws:s3:::${aws_s3_bucket.cloudtrail_bucket.bucket}/*",
          "arn:aws:s3:::${aws_s3_bucket.cloudtrail_bucket.bucket}"
        ]
      }
    ]
  })
}