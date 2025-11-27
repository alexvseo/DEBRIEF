# Guia de Segurança e Superfícies de Ataque

Este documento consolida o baseline de segurança do DeBrief. Ele orienta futuras auditorias e serve como checklist operacional durante incidentes.

## 1. Superfícies Expostas

| Componente | Porta/Host | Stack | Observações |
|------------|------------|-------|-------------|
| Frontend (Vite build + Nginx) | 2022 / `debrief.interce.com.br` | Nginx dentro do container `debrief-frontend` | Entrega SPA, depende de Caddy/nginx externo para TLS. |
| Backend FastAPI | 2023 | Uvicorn/Gunicorn | Depende de PostgreSQL, Trello API, Evolution API. |
| Evolution API (WhatsApp) | 21465 (interno) | Node.js (Baileys) | Recebe tokens em `backend/app/services/whatsapp.py`. |
| PostgreSQL | Container `debrief_db` | PostgreSQL 15 | Atualmente exposto apenas na rede Docker. |
| Redis (rate limit / sessão) | *Novo* 6379 | Redis 7 alpine | Usado para blacklist de tokens e armazenamento de CSRF. |

Scripts auxiliares (`scripts/diagnostico`, `scripts/deploy`, `conectar-banco-correto.sh`) expõem credenciais se executados sem cuidado; mantê-los fora de diretórios públicos.

## 2. Fluxos Sensíveis

1. **Login / Refresh Tokens**
   - Entradas: `username/email`, `password`, opcionalmente `X-Recaptcha-Token`, `X-TOTP-Code`.
   - Saídas: `access_token`, `refresh_token`.
   - Proteções: rate limit (`slowapi` + Redis), lockout progressivo (`users.failed_login_attempts`), MFA opcional, blacklist distribuída.

2. **Cadastro de Usuários**
   - Envia senha em texto claro para WhatsApp via Evolution API.
   - Garantir que `NotificationWhatsAppService` sanitize logs e que templates não incluam tokens.

3. **Uploads de Demanda**
   - Processamento em `UploadService`: valida extensão, assinatura binária, tamanho, ClamAV opcional.
   - Armazenamento fora do repositório (`/var/lib/debrief/uploads` por padrão).

4. **Integrações Externas**
   - **WhatsApp:** headers `apikey`, payload com número destino. Circuit breaker impede flood após 5 falhas consecutivas.
   - **Trello:** key/token extraídos do vault; respostas validadas antes de persistir.
   - **Z-API (herança):** credenciais mantidas apenas para compatibilidade e ficam desabilitadas por padrão.

## 3. Dados em Trânsito e em Repouso

- **Trânsito:** HTTPS obrigatório via Caddy. API Gateway define CSP, HSTS e restrições de origem.
- **Repouso:**
  - `users.password_hash` (bcrypt), `users.whatsapp` (`EncryptedString` via Fernet), tokens de APIs e secrets armazenados criptografados ao usar `ENCRYPTION_KEY`.
  - Backups rotativos (`scripts/backup/run-backup.sh`) criam dumps diários com limpeza de dados sensíveis (hash de emails).

## 4. Observabilidade

- Logs estruturados (`json`) via FastAPI + `uvicorn` e enviados para `stdout`.
- `scripts/diagnostico/*.sh` coletam estado de containers, filas e métricas de banco.
- Workflow `security-audit.yml` (GitHub Actions) executa SAST (Semgrep), dependabot audit e Trivy.

## 5. Plano de Resposta a Incidentes

1. **Detecção**
   - Alertas de rate limit/lockout no Redis.
   - Falhas repetidas de WhatsApp/Trello registradas em `audit_events`.
2. **Contenção**
   - Revogar tokens via `/auth/logout` + blacklist em Redis.
   - Rotacionar credenciais através do cofre (`SECRETS_PROVIDER=file|doppler`).
3. **Erradicação**
   - Aplicar patches, subir containers com imagens escaneadas.
   - Restaurar banco a partir de backup verificado (`scripts/backup/restore-latest.sh`).
4. **Recuperação**
   - Rodar `scripts/diagnostico/verificar-integridade.sh`.
   - Revisar `docs/SEGURANCA.md` para atualizar lições aprendidas.

## 6. Próximos Passos

- Revisar trimestralmente superfícies e dependências.
- Automatizar testes de invasão (DAST) em pipeline separado.
- Adicionar alertas no WhatsApp para eventos críticos (falha em backup, alta latência, etc.).

# Segurança – Superfícies e Fluxos Sensíveis

## Superfícies de ataque mapeadas

1. **Frontend React/Nginx (`porta 2022`)**
   - Expõe recursos estáticos e proxy via Caddy/Nginx.
   - Usa localStorage para guardar `access_token`, sujeito a XSS.
   - Depende de `.env` do frontend (não versionado) para apontar API/URLs.
2. **API FastAPI (`porta 2023` / container `debrief-backend`)**
   - Endpoints REST autenticados por JWT via `Authorization: Bearer`.
   - Uploads gravados em `backend/uploads/` local ao container.
   - Admin docs (Swagger/Redoc) permanecem habilitadas quando `DEBUG=True`.
3. **Evolution API v1.8.5 (`porta 21465`)**
   - Instância `debrief`, autenticada via header `apikey`.
   - Depende do número corporativo 55 85 9104-2626; sem proteção adicional além da chave.
4. **Infraestrutura de deploy**
   - `docker-compose.prod.yml` expõe portas 2022/2023 no host 82.25.92.217.
   - Scripts de deploy e diagnóstico (`scripts/deploy/*.sh`, `scripts/diagnostico/*.sh`) mantêm credenciais em texto claro.
5. **Banco PostgreSQL (`debrief_db`)**
   - Acesso regular acontece pela rede Docker; acesso remoto exige túnel SSH (`conectar-banco-correto.sh`).
   - Usuário atual `postgres` tem superuser; a aplicação usa a mesma credencial.
6. **Serviços de terceiros**
   - Trello API (chaves armazenadas no banco).
   - Z-API legado ainda presente em configs (pode expor credenciais).

## Fluxos de dados críticos

### Login (`/auth/login`)
- Entrada: `username`, `password`.
- Backend valida via `AuthService`, gera JWT (24h) e retorna ao frontend.
- Token armazenado em localStorage e anexado em todos os requests subsequentes.
- Sem MFA/captcha/bloqueio por tentativas no momento.

### Cadastro de usuário (`/auth/register` e `/usuarios/`)
- Captura dados PII (nome, email, telefone, tipo, cliente).
- Após persistência chama `notificar_usuario_cadastrado` que envia senha em texto claro por WhatsApp.
- Logs sensíveis ficam em arquivos padrão do backend (não mascarados).

### Notificações WhatsApp
- Serviço `backend/app/services/whatsapp.py` envia mensagens via Evolution API.
- Campos utilizados: `usuario_nome`, `usuario_email`, `usuario_senha`, `url_acesso`.
- Respostas externas não são validadas contra schema; falhas são apenas logadas.

### Integração Trello
- `TrelloService` usa `TRELLO_API_KEY` e `TRELLO_TOKEN` para criar/atualizar/deletar cards.
- ID do card fica salvo em `demandas.trello_card_id`; exclusão de demandas remove o card correspondente.
- Falhas de sincronização não interrompem operações (possível divergência de estado).

### Uploads de anexos
- `POST /demandas/{id}/anexos` aceita PDF/JPEG/PNG até 50 MB.
- Arquivos gravados no filesystem do container; não há antivírus nem validação por assinatura.
- Sem separação física entre uploads e código da aplicação.

### Fluxo de credenciais e deploy
- `backend/app/core/config.py` contém credenciais reais (DB, Z-API, Evolution API).
- Scripts na raiz também carregam senhas (ex.: `<redacted-db-password>`, API keys).
- Repositório fornece guias de acesso que podem ser clonados sem autenticação adicional.

## Conclusões iniciais

- Superfícies externas dependem primariamente de segredo compartilhado (JWT secret, API keys, senha PostgreSQL); não há defesa em profundidade.
- Fluxos críticos manipulam dados sensíveis em texto claro (senhas enviadas via WhatsApp, tokens armazenados em localStorage).
- Próximas etapas do plano abordarão segregação de segredos, hardening de autenticação, camadas adicionais de proteção ao banco e integrações, conforme seções 2–6.

## Medidas implementadas nesta etapa

- **Gestão de segredos:** `.env.example` (backend e docker) saneados, scripts de deploy carregam variáveis via `scripts/deploy/lib/secrets.sh` (arquivo, Doppler ou outro provider).
- **Autenticação forte:** refresh tokens rotativos em `refresh_tokens`, lockout configurável (`AUTH_MAX_FAILED_ATTEMPTS`/`AUTH_LOCKOUT_MINUTES`), MFA TOTP opcional com endpoints `/auth/2fa/*` e registro de tentativas em `login_attempts`.
- **Criptografia de PII:** campo `users.whatsapp` passa a usar `EncryptedString` (Fernet) com fallback seguro para valores legados.
- **Proteção anti-bot:** reCAPTCHA pode ser exigido em login/registro (`RECAPTCHA_REQUIRE_ON_*`), frontend envia `X-Recaptcha-Token`.
- **Rate limiting distribuído:** SlowAPI suporta Redis via `RATE_LIMIT_STORAGE_URI`, fallback para memória quando desabilitado.
- **Frontend alinhado:** login envia OTP e reCAPTCHA, exibe campo condicional de 2FA e trata respostas específicas do backend.

