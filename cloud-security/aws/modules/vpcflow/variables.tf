# modules/vpcflow/variables.tf
variable "bucket_name" {
  description = "Name of the S3 bucket to store VPC flow logs"
  type        = string
}

variable "vpc_id" {
  description = "ID of the VPC to enable flow logs for"
  type        = string
}

variable "log_format" {
  description = "The log format for VPC Flow Logs"
  type        = string
  default     = "default"
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