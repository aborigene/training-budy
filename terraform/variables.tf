variable "project_id" {
  description = "The GCP project ID"
  type        = string
  default     = "training-budy"
}

variable "region" {
  description = "The GCP region"
  type        = string
  default     = "us-central1"
}

variable "github_repo" {
  description = "The GitHub repository in format: owner/repo (e.g. user/training-budy)"
  type        = string
}

# Secret values — sourced from TF_VAR_* env vars (GitHub Actions secrets in CI,
# local shell env locally). Never read from a file so this plan applies cleanly
# from CI without committing any secret material.
variable "garmin_user" {
  description = "Garmin Connect username"
  type        = string
  sensitive   = true
}

variable "garmin_pass" {
  description = "Garmin Connect password"
  type        = string
  sensitive   = true
}

variable "anthropic_api_key" {
  description = "Anthropic API key used by the Telegram bot"
  type        = string
  sensitive   = true
}

variable "telegram_bot_token" {
  description = "Telegram Bot API token (from BotFather)"
  type        = string
  sensitive   = true
}

variable "telegram_webhook_secret" {
  description = "Secret token Telegram sends in the X-Telegram-Bot-Api-Secret-Token header; validated by the bot"
  type        = string
  sensitive   = true
}

variable "telegram_allowed_chat_id" {
  description = "Comma-separated Telegram chat IDs allowed to talk to the bot (not sensitive — just an allowlist)"
  type        = string
}