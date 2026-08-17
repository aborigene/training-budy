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