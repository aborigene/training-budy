# Cloud Run Service for the Telegram Bot
# Ingress must stay public: Telegram calls the webhook from its own
# infrastructure, not from inside GCP. The trust boundary is enforced in the
# app itself, by validating the X-Telegram-Bot-Api-Secret-Token header against
# TELEGRAM_WEBHOOK_SECRET before doing anything else.
resource "google_cloud_run_v2_service" "telegram_bot" {
  name     = "telegram-bot"
  location = var.region
  project  = var.project_id
  ingress  = "INGRESS_TRAFFIC_ALL"

  template {
    service_account = google_service_account.telegram_bot.email
    containers {
      # Initial placeholder image; GitHub Actions will deploy the real one
      image = "us-docker.pkg.dev/cloudrun/container/hello:latest"

      ports {
        container_port = 8080
      }

      env {
        name = "TELEGRAM_BOT_TOKEN"
        value_source {
          secret_key_ref {
            secret  = google_secret_manager_secret.secrets["telegram_bot_token"].secret_id
            version = "latest"
          }
        }
      }

      env {
        name = "TELEGRAM_WEBHOOK_SECRET"
        value_source {
          secret_key_ref {
            secret  = google_secret_manager_secret.secrets["telegram_webhook_secret"].secret_id
            version = "latest"
          }
        }
      }

      env {
        name = "ANTHROPIC_API_KEY"
        value_source {
          secret_key_ref {
            secret  = google_secret_manager_secret.secrets["anthropic_api_key"].secret_id
            version = "latest"
          }
        }
      }

      env {
        name  = "TELEGRAM_ALLOWED_CHAT_ID"
        value = var.telegram_allowed_chat_id
      }
    }

    execution_environment = "EXECUTION_ENVIRONMENT_GEN2"
  }

  lifecycle {
    ignore_changes = [
      template[0].containers[0].image
    ]
  }

  depends_on = [
    google_project_service.services,
    google_artifact_registry_repository.repo,
    time_sleep.wait_for_secret_iam,
  ]
}

resource "google_cloud_run_service_iam_member" "telegram_bot_invoker" {
  project  = google_cloud_run_v2_service.telegram_bot.project
  location = google_cloud_run_v2_service.telegram_bot.location
  service  = google_cloud_run_v2_service.telegram_bot.name
  role     = "roles/run.invoker"
  member   = "allUsers"
}

# Cloud Run Job for Garmin Sync
resource "google_cloud_run_v2_job" "garmin_sync_job" {
  name     = "garmin-sync-job"
  location = var.region
  project  = var.project_id

  template {
    template {
      service_account = google_service_account.garmin_job.email
      containers {
        # Initial placeholder image; GitHub Actions will deploy the real one
        image = "us-docker.pkg.dev/cloudrun/container/hello:latest"

        env {
          name = "GARMIN_USER"
          value_source {
            secret_key_ref {
              secret  = google_secret_manager_secret.secrets["garmin_user"].secret_id
              version = "latest"
            }
          }
        }

        env {
          name = "GARMIN_PASS"
          value_source {
            secret_key_ref {
              secret  = google_secret_manager_secret.secrets["garmin_pass"].secret_id
              version = "latest"
            }
          }
        }
      }
    }
  }

  lifecycle {
    ignore_changes = [
      template[0].template[0].containers[0].image
    ]
  }

  depends_on = [
    google_project_service.services,
    google_artifact_registry_repository.repo,
    time_sleep.wait_for_secret_iam,
  ]
}
