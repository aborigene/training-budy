resource "google_cloud_scheduler_job" "garmin_sync_scheduler" {
  name             = "garmin-sync-schedule"
  description      = "Trigger Garmin Sync Cloud Run Job 2x a day"
  schedule         = "0 6,18 * * *"
  time_zone        = "America/Sao_Paulo"
  project          = var.project_id
  region           = var.region

  http_target {
    http_method = "POST"
    uri         = "https://${var.region}-run.googleapis.com/apis/run.googleapis.com/v1/namespaces/${var.project_id}/jobs/${google_cloud_run_v2_job.garmin_sync_job.name}:run"

    oauth_token {
      service_account_email = google_service_account.garmin_job.email
    }
  }

  depends_on = [google_project_service.services]
}