resource "google_cloud_scheduler_job" "job" {
  name             = "gemini-health-metrics-email-summaries"
  description      = "Triggers Gemini health metrics email summaries every Monday morning at 8:30 AM ET"
  schedule         = "30 8 * * 1" # Monday morning at 8:30 AM ET
  time_zone        = "America/New_York"
  attempt_deadline = "320s"
  region           = "us-central1"

  http_target {
    http_method = "POST"
    uri         = "${google_cloud_run_v2_service.health_metrics_app.uri}/notify/email-summaries"
    body        = base64encode("{\"trigger_key\": \"${var.EMAIL_SUMMARIES_TRIGGER_KEY}\"}")

    headers = {
      "Content-Type" = "application/json"
    }

    oidc_token {
      service_account_email = google_service_account.health_metrics_sa.email
    }
  }
}
