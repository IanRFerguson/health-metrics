locals {
  health_sa_roles = [
    "storage.objectUser",
    "bigquery.dataEditor",
    "bigquery.jobUser",
    "cloudbuild.builds.editor",
    "logging.logWriter",
    "artifactregistry.createOnPushWriter",
    "run.developer",
    "iam.serviceAccountUser"
  ]
}

resource "google_service_account" "health_metrics_sa" {
  account_id   = "health-metrics-sa"
  display_name = "Health Metrics Service Account"
}

resource "google_project_iam_member" "health_metrics_sa_roles" {
  for_each = toset(local.health_sa_roles)
  project  = "ian-is-online"
  role     = "roles/${each.value}"
  member   = "serviceAccount:${google_service_account.health_metrics_sa.email}"
}
