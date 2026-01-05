resource "google_workflows_workflow" "job_orchestrator" {
  name            = "run-pipeline"
  region          = "us-central1"
  description     = "Orchestrates Load Job then Transform Job"
  service_account = google_service_account.health_metrics_sa.email

  # Using $$ to escape Terraform interpolation for Workflow variables
  source_contents = <<-EOF
    main:
      steps:
        - run_load_job:
            call: googleapis.run.v2.projects.locations.jobs.run
            args:
              name: ${google_cloud_run_v2_job.load_job.id}
            result: load_results
        
        - wait_for_load_job:
            call: googleapis.run.v2.projects.locations.operations.get
            args:
              name: $${load_results.name}
            result: op_a
        
        - check_load_job_status:
            switch:
              - condition: $${op_a.done == true}
                next: run_transform_job
            next: wait_for_load_job
        
        - run_transform_job:
            call: googleapis.run.v2.projects.locations.jobs.run
            args:
              name: ${google_cloud_run_v2_job.transform_job.id}
            result: transform_results
        
        - finish:
            return: "Both jobs completed successfully"
  EOF
}

resource "google_cloud_scheduler_job" "workflow_trigger" {
  name             = "daily-gemini-rating-trigger"
  description      = "Triggers the ML orchestration workflow"
  schedule         = "0 13,15,17,19,21,23 * * *" # Runs every two hours between 8 AM and 8 PM daily
  time_zone        = "UTC"
  region           = "us-central1"
  attempt_deadline = "320s"

  http_target {
    http_method = "POST"
    # Note: Use the /executions endpoint of your specific workflow
    uri = "https://workflowexecutions.googleapis.com/v1/${google_workflows_workflow.job_orchestrator.id}/executions"

    # Workflows expects an empty JSON body or arguments
    body = base64encode("{}")

    oauth_token {
      service_account_email = google_service_account.health_metrics_sa.email
    }
  }
}
