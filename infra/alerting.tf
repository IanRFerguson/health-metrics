# 1. Define the Email Destination
resource "google_monitoring_notification_channel" "email_me" {
  display_name = "Workflow Failure Email"
  type         = "email"
  labels = {
    email_address = var.MY_EMAIL_ADDRESS
  }
}

# 2. Define the Alert Logic
resource "google_monitoring_alert_policy" "workflow_failure_alert" {
  display_name = "Workflow Failure: ${google_workflows_workflow.job_orchestrator.name}"
  combiner     = "OR"

  # Link to the email channel created above
  notification_channels = [google_monitoring_notification_channel.email_me.name]

  conditions {
    display_name = "Workflow Execution Failed"
    condition_matched_log {
      # This filter looks for Workflow execution logs with an ERROR severity
      filter = <<-EOT
        resource.type="workflows.googleapis.com/Workflow"
        AND resource.labels.workflow_id="${google_workflows_workflow.job_orchestrator.name}"
        AND severity>=ERROR
      EOT
    }
  }

  alert_strategy {
    # Ensures you don't get 100 emails if the workflow fails repeatedly in a loop
    notification_rate_limit {
      period = "18600s" # 5 hours
    }
  }

  documentation {
    content   = "The Workflow ${google_workflows_workflow.job_orchestrator.name} has failed. Check the logs here: https://console.cloud.google.com/workflows/workflow/us-central1/${google_workflows_workflow.job_orchestrator.name}/executions"
    mime_type = "text/markdown"
  }
}
