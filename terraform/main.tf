terraform {
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~> 5.0"
    }
  }
}

provider "google" {
  project = var.project_id
  region  = var.region
}

# Enable required APIs
locals {
  services = [
    "run.googleapis.com",
    "firestore.googleapis.com",
    "secretmanager.googleapis.com",
    "cloudscheduler.googleapis.com",
    "artifactregistry.googleapis.com",
    "iam.googleapis.com",
    "cloudresourcemanager.googleapis.com",
    "sheets.googleapis.com",
    "cloudbuild.googleapis.com",
    "iamcredentials.googleapis.com"
  ]
}

resource "google_project_service" "services" {
  for_each                   = toset(local.services)
  project                    = var.project_id
  service                    = each.value
  disable_on_destroy         = false
}

# Artifact Registry for containers
resource "google_artifact_registry_repository" "repo" {
  location      = var.region
  repository_id = "training-budy-repo"
  description   = "Docker repository for training-budy containers"
  format        = "DOCKER"
  depends_on    = [google_project_service.services]
}