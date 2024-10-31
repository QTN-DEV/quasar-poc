resource "aws_iam_role" "wazuh_logs_role" {
  name               = "WazuhLogsRole"
  assume_role_policy = jsonencode({
    "Version": "2012-10-17",
    "Statement": [
      {
        "Effect": "Allow",
        "Principal": {
          "Service": "s3.amazonaws.com"
        },
        "Action": "sts:AssumeRole"
      }
    ]
  })

  tags = {
    "Environment" = var.environment
    "Project"     = "Wazuh-Integration"
  }
}

# Optional: Attach policies to the role, for example, a policy for S3 write access
resource "aws_iam_role_policy" "wazuh_s3_policy" {
  name = "WazuhS3Policy"
  role = aws_iam_role.wazuh_logs_role.id

  policy = jsonencode({
    "Version": "2012-10-17",
    "Statement": [
      {
        "Effect": "Allow",
        "Action": [
          "s3:PutObject",
          "s3:PutObjectAcl"
        ],
        "Resource": "arn:aws:s3:::${aws_s3_bucket.wazuh_logs_bucket.bucket}/*"
      }
    ]
  })
}