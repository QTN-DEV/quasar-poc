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

output "vpc_flow_logs_bucket_arn" {
  value = module.vpcflow.vpc_flow_logs_bucket_arn
}

output "vpc_flow_log_id" {
  value = module.vpcflow.vpc_flow_log_id
}

output "read_policy_arn" {
  value = module.vpcflow.read_policy_arn
}

output "delete_policy_arn" {
  value = module.vpcflow.delete_policy_arn
}

output "describe_flow_logs_policy_arn" {
  value = module.vpcflow.describe_flow_logs_policy_arn
}