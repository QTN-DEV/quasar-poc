# S3 Bucket resource
resource "aws_s3_bucket" "wazuh_logs_bucket" {
  bucket = var.bucket_name

  # Consistent tagging strategy
  tags = merge(
    {
      "Environment" = var.environment,
      "Project"     = "Wazuh-Integration"
    },
    var.default_tags
  )
}

# Separate resource for versioning configuration
resource "aws_s3_bucket_versioning" "wazuh_logs_versioning" {
  bucket = aws_s3_bucket.wazuh_logs_bucket.id

  versioning_configuration {
    status = "Enabled"
  }
}

# Separate resource for server-side encryption
resource "aws_s3_bucket_server_side_encryption_configuration" "wazuh_logs_encryption" {
  bucket = aws_s3_bucket.wazuh_logs_bucket.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

# IAM Policy to allow specified services to put objects in the bucket
resource "aws_s3_bucket_policy" "wazuh_logs_policy" {
  bucket = aws_s3_bucket.wazuh_logs_bucket.id

  policy = jsonencode({
    "Version": "2012-10-17",
    "Statement": [
      {
        "Effect": "Allow",
        "Principal": "*",
        "Action": "s3:PutObject",
        "Resource": "arn:aws:s3:::${aws_s3_bucket.wazuh_logs_bucket.bucket}/*",
        "Condition": {
          "StringEquals": {
            "aws:SourceArn": "<RELEVANT_SOURCE_ARNS>"
          }
        }
      }
    ]
  })
}