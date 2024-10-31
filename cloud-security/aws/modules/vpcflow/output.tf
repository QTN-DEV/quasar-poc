output "vpc_flow_logs_bucket_arn" {
  description = "ARN of the VPC Flow Logs S3 bucket"
  value       = aws_s3_bucket.vpc_flow_logs_bucket.arn
}

output "vpc_flow_log_id" {
  description = "ID of the VPC Flow Log"
  value       = aws_flow_log.vpc_flow_log.id
}

output "read_policy_arn" {
  description = "ARN of the read-only IAM policy for VPC Flow Logs"
  value       = aws_iam_policy.vpcflow_read_policy.arn
}

output "delete_policy_arn" {
  description = "ARN of the delete-enabled IAM policy (if enabled)"
  value       = aws_iam_policy.vpcflow_delete_policy.arn
}

output "describe_flow_logs_policy_arn" {
  description = "ARN of the IAM policy for describing VPC Flow Logs"
  value       = aws_iam_policy.describe_flow_logs_policy.arn
}