output "pubsub_topic_name" {
  value = google_pubsub_topic.pubsub_topic.name
}

output "pubsub_subscription_name" {
  value = google_pubsub_subscription.pubsub_subscription[0].name
}

output "audit_logs_sink_name" {
  value = google_logging_project_sink.audit_logs_sink.name
}

output "vpc_flow_logs_sink_name" {
  value = google_logging_project_sink.vpc_flow_logs_sink.name
}