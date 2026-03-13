resource "google_cloud_run_v2_job" "load_job" {
  name           = "load-job"
  location       = "us-central1"
  client         = "gcloud"
  client_version = "552.0.0"

  template {
    template {

      service_account = google_service_account.health_metrics_sa.email
      max_retries     = 0

      containers {
        image = "us-central1-docker.pkg.dev/ian-is-online/health-metrics/pipeline-image:latest"

        command = ["uv"]
        args    = ["run", "/app/src/health_data/main.py"]

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


resource "google_cloud_run_v2_job" "transform_job_pre_gemini" {
  name     = "transform-job-pre-gemini"
  location = "us-central1"

  template {
    template {

      service_account = google_service_account.health_metrics_sa.email
      max_retries     = 0

      containers {
        image   = "us-central1-docker.pkg.dev/ian-is-online/health-metrics/pipeline-image:latest"
        command = ["/bin/sh", "-c"]
        args    = ["cd /app/src/analytics && uv run dbt build -t cloud -s +tag:pre_gemini"]

        env {
          name  = "DBT_PROFILES_DIR"
          value = "/app/src/analytics"
        }
      }
    }
  }
}

resource "google_cloud_run_v2_job" "transform_job_post_gemini" {
  name     = "transform-job-post-gemini"
  location = "us-central1"

  template {
    template {

      service_account = google_service_account.health_metrics_sa.email
      max_retries     = 0

      containers {
        image   = "us-central1-docker.pkg.dev/ian-is-online/health-metrics/pipeline-image:latest"
        command = ["/bin/sh", "-c"]
        args    = ["cd /app/src/analytics && uv run dbt build -t cloud -s tag:post_gemini+"]

        env {
          name  = "DBT_PROFILES_DIR"
          value = "/app/src/analytics"
        }
      }
    }
  }
}

resource "google_cloud_run_v2_job" "gemini_annotations" {
  name           = "gemini-annotations"
  location       = "us-central1"
  client         = "gcloud"
  client_version = "552.0.0"

  template {
    template {

      service_account = google_service_account.health_metrics_sa.email
      max_retries     = 0

      containers {
        image = "us-central1-docker.pkg.dev/ian-is-online/health-metrics/pipeline-image:latest"

        command = ["uv"]
        args    = ["run", "/app/src/scores/main.py"]

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

        env {
          name  = "GEMINI_API_KEY"
          value = var.GEMINI_API_KEY
        }
      }
    }
  }
}
