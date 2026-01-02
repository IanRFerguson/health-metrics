resource "google_artifact_registry_repository" "health-metrics-repo" {
  location      = "us-central1"
  repository_id = "health-metrics"
  description   = "Health Metrics Docker Repository"
  format        = "DOCKER"
}
