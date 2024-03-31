
# -----------------------------------------------------
# Setup Pub/Sub Topic
# -----------------------------------------------------

resource "google_pubsub_topic" "pubsub_topic" {
  project                    = var.project_id
  name                       = var.pubsub_topic.name
  message_retention_duration = var.pubsub_topic.message_retention_duration
}

# -----------------------------------------------------
# Setup IAM restrictions for topic
# -----------------------------------------------------

resource "google_pubsub_topic_iam_binding" "webapp" {
  topic   = google_pubsub_topic.pubsub_topic.name
  role    = "roles/pubsub.publisher"
  members = [google_service_account.webapp_service_account.member]
}

resource "google_pubsub_topic_iam_binding" "cloud_function" {
  topic   = google_pubsub_topic.pubsub_topic.name
  role    = "roles/pubsub.subscriber"
  members = [google_service_account.cloud_function_service_account.member]
}
