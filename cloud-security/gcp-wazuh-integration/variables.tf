variable "project_id" {
  description = "GCP Project ID"
  type        = string
}

variable "service_account_key" {
  description = "Path to the Service Account Key JSON file"
  type        = string
}

variable "topic_name" {
  description = "Pub/Sub Topic Name"
  type        = string
}

variable "create_subscription" {
  description = "Whether to create a subscription for the Pub/Sub topic"
  type        = bool
  default     = true
}

variable "audit_logs_sink_name" {
  description = "Name for the Cloud Audit Logs Sink"
  type        = string
}

variable "audit_logs_filter" {
  description = "Filter for Cloud Audit Logs"
  type        = string
  default     = "logName=~(\"projects/.*/logs/cloudaudit.googleapis.com%2F(activity|data_access|system_event|policy)\")"
}

variable "vpc_flow_logs_sink_name" {
  description = "Name for the VPC Flow Logs Sink"
  type        = string
}

variable "vpc_flow_logs_filter" {
  description = "Filter for VPC Flow Logs"
  type        = string
  default     = ""
}