locals {
  secret_values = {
    garmin_user             = var.garmin_user
    garmin_pass              = var.garmin_pass
    anthropic_api_key        = var.anthropic_api_key
    telegram_bot_token       = var.telegram_bot_token
    telegram_webhook_secret  = var.telegram_webhook_secret
  }
}

resource "google_secret_manager_secret" "secrets" {
  for_each  = local.secret_values
  secret_id = each.key
  project   = var.project_id

  replication {
    auto {}
  }
  depends_on = [google_project_service.services]
}

# Initial secret version. secret_data is ignored on subsequent applies so that
# routine infra changes (triggered on every push) never need write access to
# secret material — rotation is a deliberate, separate action.
resource "google_secret_manager_secret_version" "secret_versions" {
  for_each    = local.secret_values
  secret      = google_secret_manager_secret.secrets[each.key].id
  secret_data = each.value

  lifecycle {
    ignore_changes = [secret_data]
  }
}

import {
  to = google_secret_manager_secret.secrets["garmin_user"]
  id = "projects/115970203752/secrets/garmin_user"
}

import {
  to = google_secret_manager_secret.secrets["garmin_pass"]
  id = "projects/115970203752/secrets/garmin_pass"
}
