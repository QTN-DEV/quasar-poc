output "cloudtrail_bucket_arn" {
  description = "ARN of the CloudTrail S3 bucket"
  value       = aws_s3_bucket.cloudtrail_bucket.arn
}

output "cloudtrail_trail_arn" {
  description = "ARN of the CloudTrail trail"
  value       = aws_cloudtrail.cloudtrail.arn
}

output "read_policy_arn" {
  description = "ARN of the read-only IAM policy for CloudTrail logs"
  value       = aws_iam_policy.cloudtrail_read_policy.arn
}

output "delete_policy_arn" {
  description = "ARN of the delete-enabled IAM policy (if enabled)"
  value       = aws_iam_policy.cloudtrail_delete_policy.arn
}