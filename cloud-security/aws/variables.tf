variable "region" {
  description = "The AWS region to deploy resources"
  type        = string
  default     = "us-east-1"
}

variable "bucket_name" {
  description = "Name of the S3 bucket"
  type        = string
}

variable "environment" {
  description = "Environment identifier (e.g., dev, prod)"
  type        = string
  default     = "prod"
}

variable "default_tags" {
  description = "Default tags applied to all resources"
  type        = map(string)
  default     = {}
}

variable "aws_profile" {
  description = "The AWS CLI profile to use for authentication"
  type        = string
  default     = "default"  # Change to match your profile name if needed
}

variable "region" {
  description = "AWS region for resources"
  type        = string
  default     = "us-east-1"
}
