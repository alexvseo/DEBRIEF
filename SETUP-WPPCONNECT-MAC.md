# 🚀 Setup WPPConnect no Mac - Contornar Bloqueio

**Objetivo:** Rodar Evolution API localmente no Mac, conectar WhatsApp (sem bloqueio), e usar no DeBrief do VPS.

**Data:** 24/11/2025  
**Por que funciona:** Seu IP local não está bloqueado pelo WhatsApp! 🎉

---

## 📋 **VISÃO GERAL**

```
┌─────────────┐         ┌──────────────┐         ┌─────────────┐
│  WhatsApp   │ ◄─────► │ Evolution API│ ◄─────► │   Túnel     │
│  (Celular)  │         │  (Seu Mac)   │         │(ngrok/CF)   │
└─────────────┘         └──────────────┘         └─────────────┘
                                                         │
                                                         ▼
                                                  ┌─────────────┐
                                                  │   Backend   │
                                                  │   (VPS)     │
                                                  └─────────────┘
```

1. Evolution API roda no seu Mac
2. WhatsApp conecta ao seu Mac (sem bloqueio!)
3. Túnel expõe para internet
4. Backend do VPS usa a URL do túnel

---

## 🔧 **PASSO 1: Instalar Dependências**

### 1.1 - Instalar Node.js (se não tiver)

```bash
# Verificar se já tem Node.js
node -v

# Se não tiver, instalar via Homebrew
brew install node@20

# Verificar instalação
node -v  # Deve mostrar v20.x.x
npm -v   # Deve mostrar 10.x.x
```

### 1.2 - Instalar Docker Desktop (Recomendado)

**Opção A: Via Homebrew**
```bash
brew install --cask docker
```

**Opção B: Download Manual**
- Site: https://www.docker.com/products/docker-desktop/
- Baixar versão para Mac (Apple Silicon ou Intel)
- Instalar e abrir Docker Desktop

**Verificar:**
```bash
docker -v
docker-compose -v
```

---

## 📦 **PASSO 2: Instalar Evolution API (Via Docker - RECOMENDADO)**

### 2.1 - Criar diretório

```bash
mkdir -p ~/wppconnect-local
cd ~/wppconnect-local
```

### 2.2 - Criar docker-compose.yml

```bash
cat > docker-compose.yml << 'EOF'
version: '3.8'

services:
  evolution-api:
    image: atendai/evolution-api:v2.1.1
    container_name: evolution-api-local
    restart: always
    ports:
      - "8080:8080"
    environment:
      # Servidor
      - SERVER_URL=http://localhost:8080
      - SERVER_PORT=8080
      
      # Autenticação
      - AUTHENTICATION_API_KEY=debrief-local-key-2024
      
      # Banco de dados (SQLite - mais simples)
      - DATABASE_ENABLED=true
      - DATABASE_PROVIDER=sqlite
      - DATABASE_CONNECTION_URI=file:./evolution.db
      
      # Logs
      - LOG_LEVEL=ERROR
      - LOG_COLOR=true
      
      # WebSocket
      - WEBSOCKET_ENABLED=false
      
      # Rabbit/Redis (desabilitado - não precisa)
      - RABBITMQ_ENABLED=false
      - REDIS_ENABLED=false
      
    volumes:
      - evolution_instances:/evolution/instances
      - evolution_store:/evolution/store
      
    networks:
      - evolution-network

volumes:
  evolution_instances:
  evolution_store:

networks:
  evolution-network:
    driver: bridge
EOF
```

### 2.3 - Iniciar Evolution API

```bash
docker-compose up -d

# Ver logs
docker-compose logs -f
```

### 2.4 - Testar

```bash
# Aguardar 10 segundos para inicializar
sleep 10

# Testar API
curl http://localhost:8080/

# Deve retornar algo como:
# {"status":"online","version":"2.1.1"}
```

---

## 📱 **PASSO 3: Criar Instância e Conectar WhatsApp**

### 3.1 - Criar instância

```bash
curl -X POST 'http://localhost:8080/instance/create' \
  -H 'apikey: debrief-local-key-2024' \
  -H 'Content-Type: application/json' \
  -d '{
    "instanceName": "debrief",
    "integration": "WHATSAPP-BAILEYS",
    "qrcode": true
  }'
```

### 3.2 - Aguardar e conectar

```bash
# Aguardar 15 segundos
sleep 15

# Iniciar conexão
curl -X GET 'http://localhost:8080/instance/connect/debrief' \
  -H 'apikey: debrief-local-key-2024'

# Aguardar mais 15 segundos para gerar QR Code
sleep 15
```

### 3.3 - Ver QR Code (Opção 1: Manager Web)

Abra no navegador:
```
http://localhost:8080/manager
```

Login:
- Server URL: `http://localhost:8080`
- API Key: `debrief-local-key-2024`

Clique em "Get QR Code" na instância `debrief` e escaneie!

### 3.4 - Ver QR Code (Opção 2: Terminal)

```bash
# Buscar QR Code
curl -s 'http://localhost:8080/instance/fetchInstances?instanceName=debrief' \
  -H 'apikey: debrief-local-key-2024' | jq -r '.[0].instance.qrcode.code'
```

Se aparecer o código, você pode gerar QR no terminal:
```bash
# Instalar qrencode se não tiver
brew install qrencode

# Gerar QR Code no terminal
curl -s 'http://localhost:8080/instance/fetchInstances?instanceName=debrief' \
  -H 'apikey: debrief-local-key-2024' | \
  jq -r '.[0].instance.qrcode.code' | \
  qrencode -t UTF8
```

### 3.5 - Escanear com WhatsApp

1. Abra WhatsApp no celular
2. Configurações → Aparelhos conectados
3. Conectar um aparelho
4. Escaneie o QR Code
5. ✅ Deve conectar sem problemas!

---

## 🌐 **PASSO 4: Expor para Internet (Túnel)**

Agora que o WhatsApp está conectado no seu Mac, precisamos expor para o VPS acessar.

### **Opção A: ngrok (Mais fácil)** ⭐

#### 4.1 - Instalar ngrok

```bash
# Via Homebrew
brew install ngrok

# Ou baixar de: https://ngrok.com/download
```

#### 4.2 - Criar conta (grátis)

- Site: https://dashboard.ngrok.com/signup
- Copiar seu authtoken

#### 4.3 - Configurar authtoken

```bash
ngrok authtoken SEU_TOKEN_AQUI
```

#### 4.4 - Iniciar túnel

```bash
ngrok http 8080
```

Você verá algo como:
```
Forwarding    https://abc123.ngrok-free.app -> http://localhost:8080
```

**Copie essa URL!** Exemplo: `https://abc123.ngrok-free.app`

#### 4.5 - Testar

```bash
curl https://abc123.ngrok-free.app/
```

### **Opção B: Cloudflare Tunnel (Grátis, melhor para produção)**

#### 4.1 - Instalar cloudflared

```bash
brew install cloudflare/cloudflare/cloudflared
```

#### 4.2 - Login

```bash
cloudflared tunnel login
```

#### 4.3 - Criar túnel

```bash
cloudflared tunnel create debrief-wpp

# Vai mostrar o ID do túnel
# Exemplo: Tunnel ID: abc123-def456-ghi789
```

#### 4.4 - Criar arquivo de config

```bash
mkdir -p ~/.cloudflared

cat > ~/.cloudflared/config.yml << 'EOF'
tunnel: SEU_TUNNEL_ID_AQUI
credentials-file: /Users/SEU_USUARIO/.cloudflared/SEU_TUNNEL_ID_AQUI.json

ingress:
  - hostname: wpp-debrief.SEU_DOMINIO.com
    service: http://localhost:8080
  - service: http_status:404
EOF
```

#### 4.5 - Criar DNS no Cloudflare

```bash
cloudflared tunnel route dns debrief-wpp wpp-debrief.SEU_DOMINIO.com
```

#### 4.6 - Iniciar túnel

```bash
cloudflared tunnel run debrief-wpp
```

---

## 🔧 **PASSO 5: Configurar Backend do VPS**

### 5.1 - Atualizar variáveis de ambiente

```bash
ssh root@82.25.92.217

cd /var/www/debrief/backend

nano .env
```

**Alterar:**
```env
# ANTES (bloqueado):
# WPP_URL=https://wpp.interce.com.br
# WPP_INSTANCE=debrief2
# WPP_TOKEN=debrief-wpp-58a2b7dda7da9474958e2a853062d5d5

# DEPOIS (seu Mac):
WPP_URL=https://abc123.ngrok-free.app
WPP_INSTANCE=debrief
WPP_TOKEN=debrief-local-key-2024
```

**Salvar:** Ctrl+O, Enter, Ctrl+X

### 5.2 - Reiniciar backend

```bash
cd /var/www/debrief
docker-compose restart backend
```

### 5.3 - Verificar logs

```bash
docker-compose logs -f backend | grep -i wpp
```

---

## ✅ **PASSO 6: Testar Integração**

### 6.1 - No DeBrief Web

1. Acesse: https://debrief.interce.com.br/admin/configuracao-whatsapp
2. Configure:
   - **Número:** seu número conectado
   - **Instância:** `debrief`
   - **Token:** `debrief-local-key-2024`
   - **Ativa:** ✅ marcar
3. Salvar
4. Clicar em "Testar Conexão"
5. ✅ Deve enviar mensagem!

---

## 📝 **COMANDOS ÚTEIS**

### Ver status da instância

```bash
curl -s 'http://localhost:8080/instance/fetchInstances?instanceName=debrief' \
  -H 'apikey: debrief-local-key-2024' | jq .
```

### Ver logs do Evolution API

```bash
cd ~/wppconnect-local
docker-compose logs -f
```

### Reiniciar Evolution API

```bash
cd ~/wppconnect-local
docker-compose restart
```

### Parar tudo

```bash
# Parar Evolution API
cd ~/wppconnect-local
docker-compose down

# Parar ngrok (Ctrl+C no terminal)
```

---

## 🔄 **MANTER RODANDO**

### Evolution API (Docker)

Já está configurado para reiniciar automaticamente (`restart: always`)

### ngrok (manter túnel aberto)

**Opção 1: Terminal dedicado**
```bash
# Abrir novo terminal e deixar rodando
ngrok http 8080
```

**Opção 2: Background (não recomendado)**
```bash
ngrok http 8080 > /dev/null 2>&1 &
```

**Opção 3: Cloudflare Tunnel (melhor)**
- Instala como serviço
- Fica rodando sempre
- Mais estável que ngrok

---

## 🐛 **TROUBLESHOOTING**

### QR Code não aparece

```bash
# Verificar se a instância existe
curl -s 'http://localhost:8080/instance/fetchInstances' \
  -H 'apikey: debrief-local-key-2024' | jq .

# Reconectar
curl -X GET 'http://localhost:8080/instance/connect/debrief' \
  -H 'apikey: debrief-local-key-2024'

# Aguardar 20-30 segundos e tentar novamente
```

### Docker não inicia

```bash
# Verificar se Docker Desktop está rodando
docker ps

# Se não, abrir Docker Desktop e aguardar iniciar
```

### Túnel não funciona

```bash
# ngrok - verificar se está rodando
ps aux | grep ngrok

# Cloudflare - verificar túnel
cloudflared tunnel list
```

### Backend não conecta

```bash
# Verificar se a URL está correta no .env
ssh root@82.25.92.217 "cat /var/www/debrief/backend/.env | grep WPP"

# Testar URL do túnel
curl https://sua-url-do-tunel.ngrok-free.app/
```

---

## ⚠️ **IMPORTANTE**

### Segurança

- ✅ O túnel expõe sua Evolution API para internet
- ✅ Use a API Key forte (`debrief-local-key-2024`)
- ✅ Não compartilhe a URL do túnel publicamente
- ✅ ngrok grátis: URL muda a cada restart

### Disponibilidade

- 🖥️ Seu **Mac precisa estar ligado** sempre
- 🌐 Precisa estar **conectado à internet**
- 🔌 Se reiniciar, **túnel precisa ser reiniciado**
- 📱 WhatsApp precisa estar **conectado no celular**

### Alternativa Futura

Quando o IP do servidor liberar (25/11 ou 26/11):
1. Parar ngrok
2. Voltar config do backend para o servidor
3. Conectar WhatsApp no servidor
4. Seu Mac pode ficar desligado

---

## 📊 **RESUMO**

```
1. ✅ Instalar Docker no Mac
2. ✅ Rodar Evolution API local
3. ✅ Conectar WhatsApp (sem bloqueio!)
4. ✅ Expor via ngrok
5. ✅ Configurar backend VPS
6. ✅ Testar e usar! 🎉
```

**Tempo total:** ~30 minutos  
**Custo:** GRÁTIS  
**Funciona:** SIM! ✅

---

**Documentação criada em:** 24/11/2025  
**Válido até:** Bloqueio do servidor liberar  
**Próxima revisão:** 25/11/2025  




