output "topic_name" {
  value = google_pubsub_topic.pubsub_topic.name
}

output "subscription_id" {
  value = google_pubsub_subscription.pubsub_subscription.name
}

output "sink_name" {
  value = google_logging_project_sink.log_sink.name
}