variable "GCS_BUCKET_NAME" {
  description = "The name of the GCS bucket for storing application data."
  type        = string
}
variable "WEBHOOK_API_KEY" {
  description = "API key for securing webhook endpoints."
  type        = string
  sensitive   = true
}

variable "MY_EMAIL_ADDRESS" {
  description = "Email address to receive alert notifications."
  type        = string
}

variable "EMAIL_SUMMARIES_TRIGGER_KEY" {
  description = "API key for triggering email summaries."
  type        = string
  sensitive   = true
}

variable "RESEND_API_KEY" {
  description = "API key for Resend email service."
  type        = string
  sensitive   = true
}

variable "GEMINI_API_KEY" {
  description = "API key for Gemini AI service."
  type        = string
  sensitive   = true
}

