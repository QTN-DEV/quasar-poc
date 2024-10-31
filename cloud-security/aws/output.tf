output "bucket_arn" {
  description = "The ARN of the S3 bucket for Wazuh logs"
  value       = aws_s3_bucket.wazuh_logs_bucket.arn
}

output "bucket_name" {
  description = "The name of the S3 bucket for Wazuh logs"
  value       = aws_s3_bucket.wazuh_logs_bucket.id
}

output "iam_role_arn" {
  value       = aws_iam_role.wazuh_logs_role.arn
  description = "ARN of the IAM role for Wazuh S3 logging."
}