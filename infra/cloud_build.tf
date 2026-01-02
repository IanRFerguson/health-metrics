resource "google_cloudbuild_trigger" "app-service-trigger" {
  name            = "build-health-metrics-service"
  location        = "us-central1"
  service_account = google_service_account.health_metrics_sa.name
  filename        = "devops/cloud-build/server-build.yaml"

  trigger_template {
    branch_name = "main"
    repo_name   = "health-metrics"
  }
}
