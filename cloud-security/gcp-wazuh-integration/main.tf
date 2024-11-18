provider "google" {
  project = var.project_id
  credentials = file(var.service_account_key)
}

# Pub/Sub Topic
resource "google_pubsub_topic" "pubsub_topic" {
  name = var.topic_name
}

# Pub/Sub Subscription
resource "google_pubsub_subscription" "pubsub_subscription" {
  name  = "${var.topic_name}-subscription"
  topic = google_pubsub_topic.pubsub_topic.name
}

# Log Sink
resource "google_logging_project_sink" "log_sink" {
  name        = var.sink_name
  destination = "pubsub.googleapis.com/projects/${var.project_id}/topics/${google_pubsub_topic.pubsub_topic.name}"
  filter      = "" # Optional: Add a filter if needed
}