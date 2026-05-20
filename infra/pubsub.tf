# Retrieve the GCS-managed service account that publishes bucket notifications
data "google_storage_project_service_account" "gcs_sa" {}

resource "google_pubsub_topic" "gcs_file_uploads" {
  name = "gcs-file-upload-notifications"
}

# Allow the GCS service account to publish to the topic
resource "google_pubsub_topic_iam_member" "gcs_publisher" {
  topic  = google_pubsub_topic.gcs_file_uploads.id
  role   = "roles/pubsub.publisher"
  member = "serviceAccount:${data.google_storage_project_service_account.gcs_sa.email_address}"
}

# Publish to the topic whenever a new object is finalized in the bucket
resource "google_storage_notification" "file_upload" {
  bucket         = google_storage_bucket.food_diary_bucket.name
  payload_format = "JSON_API_V1"
  topic          = google_pubsub_topic.gcs_file_uploads.id
  event_types    = ["OBJECT_FINALIZE"]
  depends_on     = [google_pubsub_topic_iam_member.gcs_publisher]
}

# Eventarc trigger: new Pub/Sub message → execute the pipeline workflow
resource "google_eventarc_trigger" "gcs_upload_to_workflow" {
  name     = "gcs-upload-trigger-workflow"
  location = "us-central1"

  matching_criteria {
    attribute = "type"
    value     = "google.cloud.pubsub.topic.v1.messagePublished"
  }

  transport {
    pubsub {
      topic = google_pubsub_topic.gcs_file_uploads.id
    }
  }

  destination {
    workflow = google_workflows_workflow.job_orchestrator.id
  }

  service_account = google_service_account.health_metrics_sa.email
}
