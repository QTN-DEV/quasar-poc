# S3 Bucket for VPC Flow Logs
resource "aws_s3_bucket" "vpc_flow_logs_bucket" {
  bucket = var.bucket_name

  tags = {
    "Name"        = "VPCFlowLogs"
    "Environment" = var.environment
  }
}

# VPC Flow Logs
resource "aws_flow_log" "vpc_flow_log" {
  log_destination      = aws_s3_bucket.vpc_flow_logs_bucket.arn
  log_destination_type = "s3"
  vpc_id               = var.vpc_id
  log_format           = var.log_format
  traffic_type         = "ALL"
}

# IAM Policy for Read-Only Access
resource "aws_iam_policy" "vpcflow_read_policy" {
  name        = "VPCFlowReadPolicy"
  description = "IAM policy for read-only access to VPC Flow logs in S3"

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect   = "Allow",
        Action   = ["s3:GetObject", "s3:ListBucket"],
        Resource = [
          "arn:aws:s3:::${aws_s3_bucket.vpc_flow_logs_bucket.bucket}/*",
          "arn:aws:s3:::${aws_s3_bucket.vpc_flow_logs_bucket.bucket}"
        ]
      }
    ]
  })
}

# Optional IAM Policy for Delete Access
resource "aws_iam_policy" "vpcflow_delete_policy" {
  count = var.enable_delete_permission ? 1 : 0
  name  = "VPCFlowDeletePolicy"

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect   = "Allow",
        Action   = ["s3:GetObject", "s3:ListBucket", "s3:DeleteObject"],
        Resource = [
          "arn:aws:s3:::${aws_s3_bucket.vpc_flow_logs_bucket.bucket}/*",
          "arn:aws:s3:::${aws_s3_bucket.vpc_flow_logs_bucket.bucket}"
        ]
      }
    ]
  })
}

# IAM Policy for Describing Flow Logs
resource "aws_iam_policy" "describe_flow_logs_policy" {
  name        = "DescribeFlowLogsPolicy"
  description = "IAM policy for describing VPC Flow logs"

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect   = "Allow",
        Action   = ["ec2:DescribeFlowLogs"],
        Resource = "*"
      }
    ]
  })
}