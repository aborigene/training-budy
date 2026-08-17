# Training Budy 🏃‍♂️🏊‍♂️🚴‍♂️

Plataforma de controle e análise de treinos para Ironman integrada ao Garmin Connect, Google Sheets, LibreChat e Gemini. Deploy 100% serverless na GCP com segurança Zero Trust via Tailscale.

## Estrutura do Monorepo
- `terraform/`: Infraestrutura como Código (IaC) para provisionar GCP.
- `apps/garmin-sync-job/`: Cloud Run Job sincronizando Garmin com Google Sheets.
- `apps/mcp-server/`: Cloud Run Service provendo SSE MCP Server para métricas e notas via API.
- `apps/librechat/`: Cloud Run Service rodando LibreChat integrado com Gemini e Tailscale.

## Passo a Passo de Instalação

### 1. Pré-requisitos
- Conta GCP com faturamento ativado e CLI (`gcloud`) instalada.
- Tailscale Auth Key gerada no Admin Console.
- API Key do Google Gemini.
- Conta Garmin Connect e Credenciais.
- Uma Planilha no Google Sheets (Copie o ID e crie abas "Treinos" e "Notas").

### 2. Configurar Planilha Google Sheets
Após rodar o Terraform, as Service Accounts serão criadas.
1. Acesse o Google Sheets.
2. Compartilhe a planilha concedendo permissão de "Editor" para os emails:
   - `sa-garmin-job@training-budy.iam.gserviceaccount.com`
   - `sa-mcp-server@training-budy.iam.gserviceaccount.com`

### 3. Deploy Infraestrutura (Terraform)
```bash
cd terraform
cp terraform.tfvars.example terraform.tfvars
terraform init
terraform apply
```

### 4. Cadastrar Secrets no GCP (Via Terraform Local)
Para automatizar a injeção dos Segredos diretamente no GCP Secret Manager pelo Terraform, foi criada a pasta `stuff/`. Esta pasta é **ignorada pelo Git** (`.gitignore`) para garantir a segurança.

1. Navegue até a pasta `stuff/`.
2. Crie um arquivo `.txt` para cada um dos seguintes secrets contendo *apenas* o valor do segredo (sem quebras de linha no final):
   - `garmin_user.txt`
   - `garmin_pass.txt`
   - `gemini_api_key.txt`
   - `tailscale_authkey.txt`
   - `jwt_secret.txt`
   - `jwt_refresh_secret.txt`
   - `creds_key.txt`
   - `creds_iv.txt`
   - `mongo_uri.txt` (Com a connection string do seu cluster Free Tier no MongoDB Atlas)
3. Ao executar `terraform apply`, o Terraform lerá esses arquivos locais na pasta `stuff/` e populacionará as versões iniciais dos segredos no GCP automaticamente.

### 5. Configurar Integração Contínua (GitHub Actions)
Todo o setup de `Workload Identity Federation` (acesso sem chaves) já foi gerado no seu Terraform.
1. Na primeira execução do seu `terraform apply`, guarde a saída das variáveis `workload_identity_provider` e `github_actions_sa_email`.
2. O arquivo de deploy do CI/CD já está criado em `.github/workflows/deploy.yaml`.
3. Abra esse arquivo e atualize as variáveis no step `Google Auth` com os valores devolvidos pelo Terraform (Apenas o Project Number será necessário ser ajustado).
4. Suba (Commit & Push) seu repositório para o GitHub na branch `main`.
5. O GitHub Actions iniciará automaticamente. Ele usará o `Google Cloud Build` para montar as imagens e atualizar os Cloud Runs no GCP, sem que a sua máquina local encoste no Docker.

### 6. Configuração Atalhos do iOS (Apple Shortcuts)
Crie um atalho no seu iPhone para gravar notas de voz:
1. Adicione a ação **Ditar Texto**.
2. Adicione a ação **Obter URL** com o endereço do seu MCP Server (ex: `https://mcp-server-xyz.a.run.app/notes`).
3. Adicione a ação **Obter Conteúdo da URL**, método POST.
4. No Corpo (JSON), adicione a chave `note` mapeada para o `Texto Ditado`.

### 7. Acesso Zero Trust via Tailscale
- Vá ao Console do Tailscale.
- A máquina `librechat-gcp` aparecerá na sua Tailnet.
- Como o Cloud Run tem Ingress `internal-only`, acesse a interface do LibreChat conectando sua máquina pessoal à mesma Tailnet usando o IP do Tailscale da instância.

> **Banco de Dados LibreChat (MongoDB Atlas na GCP)**: O LibreChat exige uma conexão via protocolo MongoDB. Para manter o faturamento e a gestão unificados no Google Cloud, este projeto utiliza a integração do **MongoDB Atlas provisionado via GCP Marketplace**. A `MONGO_URI` necessária pelo LibreChat será gerada na conta Atlas e salva no GCP Secret Manager.