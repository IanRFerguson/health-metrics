resource "google_cloud_run_v2_service" "health_metrics_app" {
  name                = "health-metrics-app"
  location            = "us-central1"
  deletion_protection = true
  ingress             = "INGRESS_TRAFFIC_ALL"

  client         = "gcloud"
  client_version = "529.0.0"

  traffic {
    percent = 100
    type    = "TRAFFIC_TARGET_ALLOCATION_TYPE_LATEST"
  }

  scaling {
    min_instance_count = 1
  }

  template {
    max_instance_request_concurrency = 5
    service_account                  = google_service_account.health_metrics_sa.email

    containers {
      image = "us-central1-docker.pkg.dev/ian-is-online/health-metrics/app-image:latest"

      ports {
        container_port = 5000
      }

      resources {
        startup_cpu_boost = true
        cpu_idle          = true
        limits = {
          "cpu"    = "2.0"
          "memory" = "2Gi"
        }
      }

      env {
        name  = "GCS_BUCKET_NAME"
        value = var.GCS_BUCKET_NAME
      }

      env {
        name  = "WEBHOOK_API_KEY"
        value = var.WEBHOOK_API_KEY
      }
    }
  }
}

resource "google_cloud_run_service_iam_binding" "health_metrics_app_invoker" {
  location = google_cloud_run_v2_service.health_metrics_app.location
  service  = google_cloud_run_v2_service.health_metrics_app.name
  role     = "roles/run.invoker"
  members = [
    "allUsers",
  ]
}

