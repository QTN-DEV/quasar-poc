provider "google" {
  project = var.project_id
  region  = var.region
}

# Create GCP Project (if needed) — else, manually provide project_id
resource "google_project" "wazuh_project" {
  name       = "Wazuh GCP Integration Project"
  project_id = var.project_id
  org_id     = "<YOUR_ORG_ID>"  # Optional if you have an org
}

# Service Account creation
resource "google_service_account" "wazuh_service_account" {
  account_id   = "wazuh-service-account"
  display_name = "Service Account for Wazuh GCP Integration"
}

# Attach Pub/Sub Roles to the Service Account
resource "google_project_iam_member" "pubsub_publisher" {
  project = google_project.wazuh_project.project_id
  role    = "roles/pubsub.publisher"
  member  = "serviceAccount:${google_service_account.wazuh_service_account.email}"
}

resource "google_project_iam_member" "pubsub_subscriber" {
  project = google_project.wazuh_project.project_id
  role    = "roles/pubsub.subscriber"
  member  = "serviceAccount:${google_service_account.wazuh_service_account.email}"
}

# Service Account Key
resource "google_service_account_key" "wazuh_key" {
  service_account_id = google_service_account.wazuh_service_account.id
  public_key_type    = "TYPE_X509_PEM_FILE"
}

# Pub/Sub Topic
resource "google_pubsub_topic" "wazuh_topic" {
  name = "wazuh-topic"
}

# Default Subscription to Topic
resource "google_pubsub_subscription" "wazuh_subscription" {
  name  = "wazuh-subscription"
  topic = google_pubsub_topic.wazuh_topic.id
}

# Log Sink
resource "google_logging_project_sink" "wazuh_sink" {
  name        = "wazuh-sink"
  destination = "pubsub.googleapis.com/${google_pubsub_topic.wazuh_topic.id}"
  filter      = "resource.type=gce_instance"  # Customize filter as needed

  # Grant Sink Writer permissions on the Pub/Sub topic
  unique_writer_identity = true
}

# IAM Binding for Log Sink to Publish to Pub/Sub Topic
resource "google_pubsub_topic_iam_member" "sink_writer" {
  topic = google_pubsub_topic.wazuh_topic.name
  role  = "roles/pubsub.publisher"
  member = google_logging_project_sink.wazuh_sink.writer_identity
}

resource "google_project_service" "required_apis" {
  for_each = toset([
    "iam.googleapis.com",
    "compute.googleapis.com",
    "cloudresourcemanager.googleapis.com",
    "pubsub.googleapis.com",
    "logging.googleapis.com"
  ])
  project = google_project.wazuh_project.project_id
  service = each.value
}