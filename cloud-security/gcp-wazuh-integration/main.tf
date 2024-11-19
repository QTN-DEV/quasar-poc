provider "google" {
  project     = var.project_id
  credentials = file(var.service_account_key)
}

# Pub/Sub Topic
resource "google_pubsub_topic" "pubsub_topic" {
  name = var.topic_name
}

# Optional: Pub/Sub Subscription
resource "google_pubsub_subscription" "pubsub_subscription" {
  count = var.create_subscription ? 1 : 0

  name  = "${google_pubsub_topic.pubsub_topic.name}-subscription"
  topic = google_pubsub_topic.pubsub_topic.name
}

# Cloud Audit Logs Sink
resource "google_logging_project_sink" "audit_logs_sink" {
  name        = var.audit_logs_sink_name
  destination = "pubsub.googleapis.com/projects/${var.project_id}/topics/${google_pubsub_topic.pubsub_topic.name}"
  filter      = var.audit_logs_filter
}

# VPC Flow Logs Sink
resource "google_logging_project_sink" "vpc_flow_logs_sink" {
  name        = var.vpc_flow_logs_sink_name
  destination = "pubsub.googleapis.com/projects/${var.project_id}/topics/${google_pubsub_topic.pubsub_topic.name}"
  filter      = "resource.type=\"gce_subnetwork\" AND log_name=\"projects/${var.project_id}/logs/compute.googleapis.com%2Fvpc_flows\""
}