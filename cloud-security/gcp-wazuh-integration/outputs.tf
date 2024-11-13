output "service_account_email" {
  value = google_service_account.wazuh_service_account.email
}

output "subscription_id" {
  value = google_pubsub_subscription.wazuh_subscription.id
}

output "sink_writer_identity" {
  value = google_logging_project_sink.wazuh_sink.writer_identity
}