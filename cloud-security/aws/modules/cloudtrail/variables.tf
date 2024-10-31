variable "bucket_name" {
  description = "Name of the S3 bucket to store CloudTrail logs"
  type        = string
}

variable "log_prefix" {
  description = "Log prefix to organize CloudTrail logs in the bucket"
  type        = string
  default     = "AWSLogs"
}

variable "kms_key_id" {
  description = "KMS Key ID for SSE encryption on the S3 bucket (optional)"
  type        = string
  default     = null
}

variable "enable_delete_permission" {
  description = "Flag to enable S3 delete permissions for IAM user"
  type        = bool
  default     = false
}

# Root variables.tf
variable "environment" {
  description = "The environment for this deployment (e.g., dev, staging, prod)"
  type        = string
  default     = "dev"
}