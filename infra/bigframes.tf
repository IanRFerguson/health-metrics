locals {
  required_bigframes_apis = [
    "aiplatform.googleapis.com",
    "bigqueryconnection.googleapis.com",
  ]
}

# Create the BigQuery Cloud Resource Connection
resource "google_bigquery_connection" "vertex_ai_conn" {
  connection_id = "gemini-connection"
  location      = "us" # Must match your dataset location
  friendly_name = "Gemini AI Connection"
  description   = "Used by dbt-python models to call Gemini LLMs"
  cloud_resource {}
}

# Grant the Connection's Service Account access to Vertex AI
# BigQuery automatically creates an internal service account for the connection
resource "google_project_iam_member" "connection_vertex_user" {
  project = "ian-is-online"
  role    = "roles/aiplatform.user"
  member  = "serviceAccount:${google_bigquery_connection.vertex_ai_conn.cloud_resource[0].service_account_id}"
}

# Grant your Cloud Run Service Account permission to USE the connection
# Replace with the actual SA running your Cloud Run Job
resource "google_bigquery_connection_iam_member" "cloud_run_sa_connection_user" {
  project       = google_bigquery_connection.vertex_ai_conn.project
  location      = google_bigquery_connection.vertex_ai_conn.location
  connection_id = google_bigquery_connection.vertex_ai_conn.connection_id
  role          = "roles/bigquery.connectionUser"
  member        = "serviceAccount:${google_service_account.health_metrics_sa.email}"
}

resource "google_project_service" "project" {
  project  = "ian-is-online"
  for_each = toset(local.required_bigframes_apis)
  service  = each.value
}
