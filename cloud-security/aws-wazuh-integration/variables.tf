variable "aws_region" {
  description = "AWS region"
  default = "ap-southeast-1"
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
  default     = null  # or any placeholder value
}

variable "vpc_id" {
  description = "The ID of the VPC to enable flow logs"
  type        = string
  default     = "vpc-045a4aeccfd298ab0"  # Update this to your actual VPC ID
}