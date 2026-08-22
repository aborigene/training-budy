#!/bin/bash
# Pushes local secret/config values from stuff/ into GitHub Actions
# Secrets/Variables via `gh`, so they never need to be typed into the GitHub
# UI. Requires `gh auth login` to have been run once.
#
# Usage: ./scripts/sync_github_secrets.sh

set -euo pipefail

cd "$(dirname "$0")/.."

if ! command -v gh &> /dev/null; then
    echo "Error: GitHub CLI (gh) not found. Install it first: https://cli.github.com" >&2
    exit 1
fi

# file in stuff/ -> GitHub Actions secret name
SECRET_FILES=(
    "garmin_user.txt:GARMIN_USER"
    "garmin_pass.txt:GARMIN_PASS"
    "anthropic_api_key.txt:ANTHROPIC_API_KEY"
    "telegram_bot_token.txt:TELEGRAM_BOT_TOKEN"
    "telegram_webhook_secret.txt:TELEGRAM_WEBHOOK_SECRET"
)

# file in stuff/ -> GitHub Actions variable name (non-sensitive)
VARIABLE_FILES=(
    "telegram_allowed_chat_id.txt:TELEGRAM_ALLOWED_CHAT_ID"
)

for entry in "${SECRET_FILES[@]}"; do
    file="${entry%%:*}"
    name="${entry##*:}"
    path="stuff/$file"
    if [ ! -f "$path" ]; then
        echo "Skipping $name — $path not found." >&2
        continue
    fi
    echo "Setting secret $name from $path"
    gh secret set "$name" < "$path"
done

for entry in "${VARIABLE_FILES[@]}"; do
    file="${entry%%:*}"
    name="${entry##*:}"
    path="stuff/$file"
    if [ ! -f "$path" ]; then
        echo "Skipping $name — $path not found." >&2
        continue
    fi
    echo "Setting variable $name from $path"
    gh variable set "$name" < "$path"
done

echo "Done."
