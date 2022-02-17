resource "google_cloud_scheduler_job" "job" {
  name             = var.job_name
  description      = var.job_description
  schedule         = var.cron
  region           = var.region
  time_zone        = "America/New_York"
  attempt_deadline = "320s"

  retry_config {
    retry_count = 1
  }

  http_target {
    http_method = "POST"
    uri         = var.url
    body        = base64encode(var.body)
    oidc_token {
      audience = var.audience
      service_account_email = var.service_account
    }
  }
}