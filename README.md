# Training Budy 🏃‍♂️🏊‍♂️🚴‍♂️

Plataforma de controle e análise de treinos para Ironman integrada ao Garmin Connect, Google Sheets e um bot do Telegram como interface, usando a Claude API. Deploy 100% serverless na GCP.

## Estrutura do Monorepo
- `terraform/`: Infraestrutura como Código (IaC) para provisionar GCP.
- `apps/garmin-sync-job/`: Cloud Run Job sincronizando Garmin com Google Sheets.
- `apps/telegram-bot/`: Cloud Run Service que recebe mensagens via webhook do Telegram e responde usando a Claude API.

> Arquitetura anterior (LibreChat + MongoDB Atlas + Tailscale + MCP Server) foi descontinuada — o roteamento do Tailscale em modo userspace dentro do Cloud Run se mostrou inviável. Ver histórico no git para detalhes.

## Passo a Passo de Instalação

### 1. Pré-requisitos
- Conta GCP com faturamento ativado e CLI (`gcloud`) instalada.
- [GitHub CLI (`gh`)](https://cli.github.com) instalado e autenticado (`gh auth login`).
- Chave da Anthropic API (console.anthropic.com) — cobrança separada de uma eventual assinatura Claude.ai.
- Bot do Telegram criado via [@BotFather](https://t.me/BotFather) (token) e seu `chat_id` pessoal.
- Conta Garmin Connect e Credenciais.
- Uma Planilha no Google Sheets (Copie o ID e crie abas "Treinos" e "Notas") — usada a partir da Fase 2.

### 2. Bootstrap do backend remoto do Terraform
O state do Terraform vive num bucket GCS (não mais local), para evitar drift entre execuções locais e do CI:
```bash
gcloud storage buckets create gs://training-budy-v2-tfstate --project=training-budy-v2 --location=us-central1 --uniform-bucket-level-access
```

### 3. Cadastrar os segredos localmente
1. Crie um arquivo `.txt` para cada segredo dentro de `stuff/` (pasta ignorada pelo Git), contendo *apenas* o valor (sem quebra de linha no final):
   - `garmin_user.txt`, `garmin_pass.txt`
   - `anthropic_api_key.txt`
   - `telegram_bot_token.txt`
   - `telegram_webhook_secret.txt` (qualquer string aleatória longa — é validada pelo bot, não pelo Telegram)
   - `telegram_allowed_chat_id.txt` (seu chat_id do Telegram — não sensível, mas mantido junto por conveniência)
2. Rode `./scripts/sync_github_secrets.sh` — ele lê esses arquivos e configura os GitHub Actions Secrets/Variables via `gh`, sem passar pela UI do GitHub.

### 4. Primeiro apply (local, obrigatório uma vez)
O Service Account do GitHub Actions só ganha permissão de rodar `terraform apply` remotamente *depois* que um apply local conceder essa permissão a ele — então a primeira execução precisa ser local:
```bash
cd terraform
cp terraform.tfvars.example terraform.tfvars   # ajuste project_id/region/github_repo
export TF_VAR_garmin_user=$(cat ../stuff/garmin_user.txt)
export TF_VAR_garmin_pass=$(cat ../stuff/garmin_pass.txt)
export TF_VAR_anthropic_api_key=$(cat ../stuff/anthropic_api_key.txt)
export TF_VAR_telegram_bot_token=$(cat ../stuff/telegram_bot_token.txt)
export TF_VAR_telegram_webhook_secret=$(cat ../stuff/telegram_webhook_secret.txt)
export TF_VAR_telegram_allowed_chat_id=$(cat ../stuff/telegram_allowed_chat_id.txt)
terraform init
terraform apply
```
Guarde a saída de `workload_identity_provider` e `github_actions_sa_email` (já referenciadas em [.github/workflows/deploy.yaml](.github/workflows/deploy.yaml)).

### 5. Deploy contínuo (GitHub Actions)
A partir daqui, todo push em `main` que toque em `apps/**` ou `terraform/**` dispara o workflow: ele roda `terraform apply` (usando os `TF_VAR_*` injetados dos secrets configurados no passo 3) e depois builda/publica as imagens via Cloud Build.

### 6. Registrar o webhook do Telegram
Depois do primeiro deploy, pegue a URL do serviço (`terraform output telegram_bot_url`) e registre o webhook:
```bash
curl -X POST "https://api.telegram.org/bot$(cat stuff/telegram_bot_token.txt)/setWebhook" \
  -d "url=<TELEGRAM_BOT_URL>/webhook" \
  -d "secret_token=$(cat stuff/telegram_webhook_secret.txt)"
```

### 7. Configuração Atalhos do iOS (Apple Shortcuts) — Fase 2
Envie notas de voz direto para o bot via [sendMessage da API do Telegram](https://core.telegram.org/bots/api#sendmessage), usando o app **Obter Conteúdo da URL** do Atalhos.