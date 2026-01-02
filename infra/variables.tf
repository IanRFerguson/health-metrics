variable "GCS_BUCKET_NAME" {
  description = "The name of the GCS bucket for storing application data."
  type        = string
}
variable "WEBHOOK_API_KEY" {
  description = "API key for securing webhook endpoints."
  type        = string
  sensitive   = true
}
