#!/bin/bash

echo "Setting up Training Budy environment..."

PROJECT_ID="training-budy"
gcloud config set project $PROJECT_ID

gcloud services enable run.googleapis.com \
    secretmanager.googleapis.com \
    cloudscheduler.googleapis.com \
    artifactregistry.googleapis.com

echo "Setup script completed. Please apply Terraform to provision resources."