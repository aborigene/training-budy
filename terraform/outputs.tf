output "telegram_bot_url" {
  value       = google_cloud_run_v2_service.telegram_bot.uri
  description = "URL of the Telegram Bot service (set this as the Telegram webhook target)"
}

output "artifact_registry_repo" {
  value       = google_artifact_registry_repository.repo.name
  description = "Artifact Registry Repository Name"
}

output "workload_identity_provider" {
  value       = google_iam_workload_identity_pool_provider.github_provider.name
  description = "The Workload Identity Provider ID needed for GitHub Actions"
}

output "github_actions_sa_email" {
  value       = google_service_account.github_actions.email
  description = "The Service Account email needed for GitHub Actions"
}