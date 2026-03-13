locals {
  cron_schedule = "0 13,15,17 * * *" # Run at 8 AM, 12 PM, and 5 PM daily Eastern Time
}

resource "google_workflows_workflow" "job_orchestrator" {
  name            = "run-pipeline"
  region          = "us-central1"
  description     = "Orchestrates Load Job then Transform Job"
  service_account = google_service_account.health_metrics_sa.email

  # Using $$ to escape Terraform interpolation for Workflow variables
  source_contents = <<-EOF
    main:
      steps:
        # 1. Load job
        - run_load_job:
            call: googleapis.run.v2.projects.locations.jobs.run
            args:
              name: ${google_cloud_run_v2_job.load_job.id}
            result: load_op
        
        - wait_load_job:
            call: googleapis.run.v2.projects.locations.operations.get
            args:
              name: $${load_op.name}
            result: load_status
        
        - check_load_job:
            switch:
              - condition: $${load_status.done == true}
                next: run_dbt_pre_gemini
            next: wait_load_job
        
        # 2. DBT pre-gemini
        - run_dbt_pre_gemini:
            call: googleapis.run.v2.projects.locations.jobs.run
            args:
              name: ${google_cloud_run_v2_job.transform_job_pre_gemini.id}
            result: dbt_pre_op
        
        - wait_dbt_pre_gemini:
            call: googleapis.run.v2.projects.locations.operations.get
            args:
              name: $${dbt_pre_op.name}
            result: dbt_pre_status
        
        - check_dbt_pre_gemini:
            switch:
              - condition: $${dbt_pre_status.done == true}
                next: run_gemini_annotations
            next: wait_dbt_pre_gemini
        
        # 3. Gemini annotations
        - run_gemini_annotations:
            call: googleapis.run.v2.projects.locations.jobs.run
            args:
              name: ${google_cloud_run_v2_job.gemini_annotations.id}
            result: gemini_op
        
        - wait_gemini_annotations:
            call: googleapis.run.v2.projects.locations.operations.get
            args:
              name: $${gemini_op.name}
            result: gemini_status
        
        - check_gemini_annotations:
            switch:
              - condition: $${gemini_status.done == true}
                next: run_dbt_post_gemini
            next: wait_gemini_annotations
        
        # 4. DBT post-gemini
        - run_dbt_post_gemini:
            call: googleapis.run.v2.projects.locations.jobs.run
            args:
              name: ${google_cloud_run_v2_job.transform_job_post_gemini.id}
            result: dbt_post_op
        
        - wait_dbt_post_gemini:
            call: googleapis.run.v2.projects.locations.operations.get
            args:
              name: $${dbt_post_op.name}
            result: dbt_post_status
        
        - check_dbt_post_gemini:
            switch:
              - condition: $${dbt_post_status.done == true}
                next: finish
            next: wait_dbt_post_gemini
        
        - finish:
            return: "Pipeline completed successfully"
  EOF
}

resource "google_cloud_scheduler_job" "workflow_trigger" {
  name             = "pipeline-workflow-trigger"
  description      = "Triggers the ML orchestration workflow"
  schedule         = local.cron_schedule
  time_zone        = "UTC"
  region           = "us-central1"
  attempt_deadline = "320s"

  http_target {
    http_method = "POST"
    # Note: Use the /executions endpoint of your specific workflow
    uri = "https://workflowexecutions.googleapis.com/v1/${google_workflows_workflow.job_orchestrator.id}/executions"

    # Workflows expects an empty JSON body or arguments
    body = base64encode("{}")
    headers = {
      "Content-Type" = "application/json"
    }

    oauth_token {
      service_account_email = google_service_account.health_metrics_sa.email
    }
  }
}
