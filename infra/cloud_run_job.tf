resource "google_cloud_run_v2_job" "load_job" {
  name     = "load-job"
  location = "us-central1"

  template {
    template {
      containers {
        image = "us-central1-docker.pkg.dev/ian-is-online/health-metrics/pipeline-image:latest"

        command = ["python"]
        args    = ["/app/src/health_data/main.py"]

        env {
          name  = "STAGE"
          value = "production"
        }

        env {
          name  = "DESTINATION_SCHEMA_PROD"
          value = "health"
        }

        env {
          name  = "GCS_BUCKET_NAME"
          value = var.GCS_BUCKET_NAME
        }
      }
    }
  }
}
