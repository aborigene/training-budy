# Service Accounts
resource "google_service_account" "garmin_job" {
  account_id   = "sa-garmin-job"
  display_name = "SA Garmin Job"
}

resource "google_service_account" "mcp_server" {
  account_id   = "sa-mcp-server"
  display_name = "SA MCP Server"
}

resource "google_service_account" "librechat" {
  account_id   = "sa-librechat"
  display_name = "SA LibreChat"
}

# Roles for Secret Manager
resource "google_project_iam_member" "garmin_job_secret_accessor" {
  project = var.project_id
  role    = "roles/secretmanager.secretAccessor"
  member  = "serviceAccount:${google_service_account.garmin_job.email}"
}

resource "google_project_iam_member" "mcp_server_secret_accessor" {
  project = var.project_id
  role    = "roles/secretmanager.secretAccessor"
  member  = "serviceAccount:${google_service_account.mcp_server.email}"
}

resource "google_project_iam_member" "librechat_secret_accessor" {
  project = var.project_id
  role    = "roles/secretmanager.secretAccessor"
  member  = "serviceAccount:${google_service_account.librechat.email}"
}

# Roles for Firestore (LibreChat)
resource "google_project_iam_member" "librechat_firestore_user" {
  project = var.project_id
  role    = "roles/datastore.user"
  member  = "serviceAccount:${google_service_account.librechat.email}"
}

# Workload Identity Federation for GitHub Actions
resource "google_iam_workload_identity_pool" "github_pool" {
  workload_identity_pool_id = "github-actions-pool-v2"
  display_name              = "GitHub Actions Pool"
  description               = "Identity pool for GitHub Actions CI/CD"
  project                   = var.project_id
  depends_on                = [google_project_service.services]
}

resource "google_iam_workload_identity_pool_provider" "github_provider" {
  workload_identity_pool_id          = google_iam_workload_identity_pool.github_pool.workload_identity_pool_id
  workload_identity_pool_provider_id = "github-provider"
  display_name                       = "GitHub Provider"
  project                            = var.project_id
  
  attribute_mapping = {
    "google.subject"       = "assertion.sub"
    "attribute.actor"      = "assertion.actor"
    "attribute.repository" = "assertion.repository"
  }
  
  attribute_condition = "assertion.repository == '${var.github_repo}'"
  
  oidc {
    issuer_uri = "https://token.actions.githubusercontent.com"
  }
}

# Service Account for GitHub Actions
resource "google_service_account" "github_actions" {
  account_id   = "sa-github-actions"
  display_name = "Service Account for GitHub Actions"
  project      = var.project_id
}

# Allow GitHub repository to impersonate this Service Account
# Allow Cloud Build to access default Cloud Storage bucket created for logs/source
resource "google_project_iam_member" "github_actions_storage_admin" {
  project = var.project_id
  role    = "roles/storage.admin"
  member  = "serviceAccount:${google_service_account.github_actions.email}"
}

# Required for Workload Identity to interact with the bucket and APIs
resource "google_project_iam_member" "github_actions_service_usage_consumer" {
  project = var.project_id
  role    = "roles/serviceusage.serviceUsageConsumer"
  member  = "serviceAccount:${google_service_account.github_actions.email}"
}

resource "google_service_account_iam_member" "github_actions_workload_identity_user" {
  service_account_id = google_service_account.github_actions.name
  role               = "roles/iam.workloadIdentityUser"
  # IMPORTANT: The user must replace 'YOUR_GITHUB_ORG/YOUR_REPO_NAME' with their actual repository in variables.
  member             = "principalSet://iam.googleapis.com/${google_iam_workload_identity_pool.github_pool.name}/attribute.repository/${var.github_repo}"
}

# Grant permissions to the GitHub Actions Service Account

# Required for GitHub actions to run Cloud Build (needs to act as the Cloud Build service account)
resource "google_project_iam_member" "github_actions_actas_all" {
  project = var.project_id
  role    = "roles/iam.serviceAccountUser"
  member  = "serviceAccount:${google_service_account.github_actions.email}"
}

# Required to allow GitHub Actions to stream and read logs from Cloud Build
resource "google_project_iam_member" "github_actions_logs_viewer" {
  project = var.project_id
  role    = "roles/logging.viewer"
  member  = "serviceAccount:${google_service_account.github_actions.email}"
}

# Required for Cloud Build to read logs from its own internal buckets properly
resource "google_project_iam_member" "github_actions_storage_object_viewer" {
  project = var.project_id
  role    = "roles/storage.objectViewer"
  member  = "serviceAccount:${google_service_account.github_actions.email}"
}

# Required viewer role for log streaming
resource "google_project_iam_member" "github_actions_viewer" {
  project = var.project_id
  role    = "roles/viewer"
  member  = "serviceAccount:${google_service_account.github_actions.email}"
}

resource "google_project_iam_member" "github_actions_artifact_admin" {
  project = var.project_id
  role    = "roles/artifactregistry.writer"
  member  = "serviceAccount:${google_service_account.github_actions.email}"
}

resource "google_project_iam_member" "github_actions_cloudbuild_editor" {
  project = var.project_id
  role    = "roles/cloudbuild.builds.editor"
  member  = "serviceAccount:${google_service_account.github_actions.email}"
}

resource "google_project_iam_member" "github_actions_run_admin" {
  project = var.project_id
  role    = "roles/run.admin"
  member  = "serviceAccount:${google_service_account.github_actions.email}"
}

# Required to deploy Cloud Run services (act as the service accounts attached to the runners)
resource "google_service_account_iam_member" "github_actions_actas_mcp" {
  service_account_id = google_service_account.mcp_server.name
  role               = "roles/iam.serviceAccountUser"
  member             = "serviceAccount:${google_service_account.github_actions.email}"
}

resource "google_service_account_iam_member" "github_actions_actas_librechat" {
  service_account_id = google_service_account.librechat.name
  role               = "roles/iam.serviceAccountUser"
  member             = "serviceAccount:${google_service_account.github_actions.email}"
}

resource "google_service_account_iam_member" "github_actions_actas_garmin" {
  service_account_id = google_service_account.garmin_job.name
  role               = "roles/iam.serviceAccountUser"
  member             = "serviceAccount:${google_service_account.github_actions.email}"
}

