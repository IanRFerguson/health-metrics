resource "google_cloudbuild_trigger" "app-service-trigger" {
  name            = "build-health-metrics-service"
  description     = "Rebuilds the health-metrics app service on code changes"
  location        = "us-central1"
  service_account = google_service_account.health_metrics_sa.name
  filename        = "devops/cloud-build/server-build.yaml"

  repository_event_config {
    repository = "projects/ian-is-online/locations/us-central1/connections/ianferguson/repositories/IanRFerguson-health-metrics"

    push {
      branch       = "main"
      invert_regex = false
    }
  }
}
