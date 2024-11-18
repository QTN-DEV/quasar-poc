variable "project_id" {
  description = "GCP Project ID"
  type        = string
}

variable "topic_name" {
  description = "Pub/Sub Topic Name"
  type        = string
}

variable "sink_name" {
  description = "Log Sink Name"
  type        = string
}

variable "service_account_key" {
  description = "Path to the Service Account Key JSON file"
  type        = string
}