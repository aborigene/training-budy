# Cloud Run Service for MCP Server (SSE)
resource "google_cloud_run_v2_service" "mcp_server" {
  name     = "mcp-server"
  location = var.region
  project  = var.project_id
  ingress  = "INGRESS_TRAFFIC_ALL"

  template {
    service_account = google_service_account.mcp_server.email
    containers {
      # Initial placeholder image; GitHub Actions will deploy the real one
      image = "us-docker.pkg.dev/cloudrun/container/hello:latest"
      
      env {
        name  = "PROJECT_ID"
        value = var.project_id
      }
    }
  }

  depends_on = [google_project_service.services, google_artifact_registry_repository.repo]
}

# Allow unauthenticated invocation for MCP Server HTTP POST endpoint
resource "google_cloud_run_service_iam_member" "mcp_server_invoker" {
  project  = google_cloud_run_v2_service.mcp_server.project
  location = google_cloud_run_v2_service.mcp_server.location
  service  = google_cloud_run_v2_service.mcp_server.name
  role     = "roles/run.invoker"
  member   = "allUsers"
}

# Cloud Run Service for LibreChat (Multi-container sidecar Tailscale)
resource "google_cloud_run_v2_service" "librechat" {
  name     = "librechat"
  location = var.region
  project  = var.project_id
  ingress  = "INGRESS_TRAFFIC_INTERNAL_ONLY"

  template {
    service_account = google_service_account.librechat.email
    
    # LibreChat Container
    containers {
      name  = "librechat"
      # Initial placeholder image; GitHub Actions will deploy the real one
      image = "us-docker.pkg.dev/cloudrun/container/hello:latest"
      
      ports {
        container_port = 3080
      }

      env {
        name = "TAILSCALE_AUTHKEY"
        value_source {
          secret_key_ref {
            secret  = google_secret_manager_secret.secrets["tailscale_authkey"].secret_id
            version = "latest"
          }
        }
      }
      
      env {
        name = "GEMINI_API_KEY"
        value_source {
          secret_key_ref {
            secret  = google_secret_manager_secret.secrets["gemini_api_key"].secret_id
            version = "latest"
          }
        }
      }
      
      env { 
        name  = "HOST"
        value = "0.0.0.0" 
      }

            env {
        name  = "ALLOW_EMAIL_LOGIN"
        value = "true"
      }

      env {
        name  = "ALLOW_REGISTRATION"
        value = "true"
      }
      
      env {
        name = "MONGO_URI"
        value_source {
          secret_key_ref {
            secret  = google_secret_manager_secret.secrets["mongo_uri"].secret_id
            version = "latest"
          }
        }
      }
    }
    
    execution_environment = "EXECUTION_ENVIRONMENT_GEN2"
  }
  
  lifecycle {
    ignore_changes = [
      template[0].containers[0].image
    ]
  }

  depends_on = [google_project_service.services, google_artifact_registry_repository.repo]
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

  depends_on = [google_project_service.services, google_artifact_registry_repository.repo]
}


