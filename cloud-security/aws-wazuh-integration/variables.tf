variable "aws_region" {
  description = "AWS region"
  default = "us-east-1"
}

variable "use_existing_bucket" {
  description = "True if using an existing S3 bucket, else False"
  type = bool
  default = false
}

variable "bucket_name" {
  description = "Name of the S3 bucket for logs"
  type = string
}

variable "iam_group_name" {
  description = "IAM user group name"
  type = string
}

variable "iam_role_arn" {
  description = "IAM Role ARN for Flow Logs"
  type = string
}

variable "vpc_id" {
  description = "VPC ID for which flow logs will be enabled"
  type = string
}