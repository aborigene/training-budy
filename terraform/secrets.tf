locals {
  # Add mongo_uri to the secrets list
  secrets = [
    "garmin_user",
    "garmin_pass",
    "gemini_api_key",
    "tailscale_authkey",
    "jwt_secret",
    "jwt_refresh_secret",
    "creds_key",
    "creds_iv",
    "mongo_uri"
  ]
}

resource "google_secret_manager_secret" "secrets" {
  for_each  = toset(local.secrets)
  secret_id = each.value
  project   = var.project_id

  replication {
    auto {}
  }
  depends_on = [google_project_service.services]
}

# Add a data block to read from the stuff folder
# If the file exists, it will populate the secret version. If not, it will ignore.
locals {
  stuff_dir = "${path.module}/../stuff"
}

resource "google_secret_manager_secret_version" "secret_versions" {
  for_each = toset(local.secrets)
  secret   = google_secret_manager_secret.secrets[each.key].id
  
  # Read the value from the file in the stuff/ directory. 
  # If the file is missing, Terraform will fail, enforcing the existence of the stuff directory for CI/CD or local runs.
  secret_data = file("${local.stuff_dir}/${each.key}.txt")
}