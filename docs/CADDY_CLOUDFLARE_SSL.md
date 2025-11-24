# 🔒 Caddy + Cloudflare SSL - Configuração Completa

## 📋 Resumo

Configuração do Caddy com suporte a **DNS Challenge do Cloudflare** para obtenção automática de certificados SSL/TLS via Let's Encrypt.

**Data:** 23/11/2025  
**Status:** ✅ Operacional

---

## 🎯 Problema Resolvido

### **Antes:**
- ❌ Erro 525 (SSL Handshake Failed)
- ❌ Cloudflare proxy bloqueando HTTP-01 challenge
- ❌ Dois containers Caddy competindo pelas portas 80/443

### **Depois:**
- ✅ Certificados SSL válidos via DNS Challenge
- ✅ HTTPS funcionando em todos os domínios
- ✅ Renovação automática configurada
- ✅ Container único gerenciando tudo

---

## 🔑 Token Cloudflare

### **Criação do Token**

1. Acesse: https://dash.cloudflare.com/profile/api-tokens
2. Clique em **"Create Token"**
3. Selecione **"Edit zone DNS"** ou **"Create Custom Token"**
4. Configure:
   ```
   Token name: Caddy DeBrief DNS
   
   Permissions:
   └── Zone → DNS → Edit
   
   Zone Resources:
   └── Include → Specific zone → interce.com.br
   ```
5. Copie o token gerado (só aparece uma vez!)

### **Token Atual**

```
Token: Gx165Srcmm3_BW72YJKVwJ7F4hdCJrfb3AzjwGOf
Status: ✅ Válido e ativo
Verificação: curl -H "Authorization: Bearer <token>" \
  https://api.cloudflare.com/client/v4/user/tokens/verify
```

### **Configuração no Servidor**

Arquivo: `/root/caddy/.env`
```bash
CLOUDFLARE_API_TOKEN=Gx165Srcmm3_BW72YJKVwJ7F4hdCJrfb3AzjwGOf
```

Permissões:
```bash
chmod 600 /root/caddy/.env
```

---

## 🐳 Docker Compose

Arquivo: `/root/caddy/docker-compose.yml`

```yaml
version: '3.8'

services:
  caddy:
    image: slothcroissant/caddy-cloudflaredns:latest
    container_name: caddy-global
    restart: unless-stopped
    
    ports:
      - "80:80"
      - "443:443"
    
    volumes:
      - ./Caddyfile:/etc/caddy/Caddyfile:ro
      - ./sites:/etc/caddy/sites:ro
      - caddy_data:/data
      - caddy_config:/config
      - ./logs:/var/log/caddy
    
    env_file:
      - .env
    
    networks:
      - caddy-network
    
    healthcheck:
      test: ["CMD", "caddy", "version"]
      interval: 30s
      timeout: 10s
      retries: 3

volumes:
  caddy_data:
  caddy_config:

networks:
  caddy-network:
    external: true
```

**Imagem:** `slothcroissant/caddy-cloudflaredns:latest`  
**Motivo:** Inclui o módulo `caddy-dns/cloudflare` pré-compilado

---

## 📝 Configurações do Site

### **DeBrief** (`/root/caddy/sites/debrief.caddy`)

```caddyfile
debrief.interce.com.br {
    # DNS Challenge com Cloudflare
    tls {
        dns cloudflare {env.CLOUDFLARE_API_TOKEN}
    }
    
    # Compressão
    encode gzip zstd
    
    # API Backend (porta 8000)
    handle /api/* {
        reverse_proxy localhost:8000 {
            header_up Host {host}
            header_up X-Real-IP {remote_host}
        }
    }
    
    # Frontend (porta 3000)
    handle {
        reverse_proxy localhost:3000 {
            header_up Host {host}
            header_up X-Real-IP {remote_host}
        }
    }
    
    # Logs
    log {
        output file /var/log/caddy/debrief.log
        level INFO
    }
}
```

### **WPPConnect** (`/root/caddy/sites/wpp.caddy`)

```caddyfile
wpp.interce.com.br {
    # DNS Challenge com Cloudflare
    tls {
        dns cloudflare {env.CLOUDFLARE_API_TOKEN}
    }
    
    # CORS para API
    @options method OPTIONS
    handle @options {
        header {
            Access-Control-Allow-Origin *
            Access-Control-Allow-Methods "GET, POST, PUT, DELETE, OPTIONS"
            Access-Control-Allow-Headers "Content-Type, Authorization"
            Access-Control-Max-Age "3600"
        }
        respond 204
    }
    
    # Proxy para Evolution API
    reverse_proxy localhost:21465 {
        header_up Host {host}
        header_up X-Real-IP {remote_host}
        header_up X-Forwarded-Host {host}
    }
    
    # Headers de segurança
    header {
        Strict-Transport-Security "max-age=31536000;"
        X-Content-Type-Options "nosniff"
        X-Frame-Options "SAMEORIGIN"
        -Server
    }
    
    # Logs
    log {
        output file /var/log/caddy/wpp.log
        level INFO
    }
}
```

### **Caddyfile Global** (`/root/caddy/Caddyfile`)

```caddyfile
{
    email alexwebstudio@gmail.com
    log default {
        output file /var/log/caddy/access.log
        format console
    }
}

# Importar configurações dos sites
import /etc/caddy/sites/*.caddy
```

---

## 📊 Certificados

### **Localização no Container**

```
/data/caddy/certificates/
├── acme-v02.api.letsencrypt.org-directory/
│   ├── debrief.interce.com.br/
│   │   ├── debrief.interce.com.br.crt
│   │   └── debrief.interce.com.br.key
│   └── wpp.interce.com.br/
│       ├── wpp.interce.com.br.crt
│       └── wpp.interce.com.br.key
└── acme.zerossl.com-v2-dv90/
    └── ...
```

### **Validade**

```bash
Domain: debrief.interce.com.br
├── Válido de: 23/11/2025 22:50:25 GMT
├── Válido até: 21/02/2026 22:50:24 GMT
├── Emissor: Let's Encrypt
└── Método: DNS Challenge (Cloudflare)

Domain: wpp.interce.com.br
├── Válido de: 23/11/2025 22:50:25 GMT
├── Válido até: 21/02/2026 22:50:24 GMT
├── Emissor: Let's Encrypt
└── Método: DNS Challenge (Cloudflare)
```

### **Verificar Certificado**

```bash
# No servidor
docker cp caddy-global:/data/caddy/certificates/acme-v02.api.letsencrypt.org-directory/debrief.interce.com.br/debrief.interce.com.br.crt /tmp/cert.crt

openssl x509 -in /tmp/cert.crt -noout -dates -subject

# Externamente
curl -vI https://debrief.interce.com.br 2>&1 | grep -E 'SSL|certificate|issuer'
```

---

## 🚀 Deploy

### **Script de Deploy** (`/root/caddy/deploy-cloudflare.sh`)

```bash
#!/bin/bash

echo "========================================"
echo "CADDY + CLOUDFLARE DNS - Deploy Script"
echo "========================================"

# Verificar token
if [ -z "$CLOUDFLARE_API_TOKEN" ] && [ -z "$(grep CLOUDFLARE_API_TOKEN .env | cut -d= -f2)" ]; then
    echo "⚠️  ATENÇÃO: Token do Cloudflare não configurado!"
    exit 1
fi

echo "📦 Parando container antigo..."
docker-compose down

echo "🔄 Baixando nova imagem..."
docker-compose pull

echo "🚀 Iniciando novo container..."
docker-compose up -d

echo "⏳ Aguardando container iniciar..."
sleep 5

echo "✅ Verificando status..."
docker ps --filter "name=caddy-global"

echo ""
echo "📋 Logs (últimas 20 linhas):"
docker logs caddy-global --tail 20

echo ""
echo "========================================"
echo "Deploy concluído!"
echo "========================================"
```

### **Executar Deploy**

```bash
cd /root/caddy
chmod +x deploy-cloudflare.sh
./deploy-cloudflare.sh
```

---

## 🔧 Comandos Úteis

### **Verificar Status**

```bash
docker ps --filter "name=caddy-global"
docker logs caddy-global --tail 50
docker logs caddy-global -f  # Seguir logs em tempo real
```

### **Reload Configuração**

```bash
docker exec caddy-global caddy reload --config /etc/caddy/Caddyfile
```

### **Forçar Renovação de Certificado**

```bash
docker exec caddy-global caddy reload --config /etc/caddy/Caddyfile --force
```

### **Ver Certificados**

```bash
docker exec caddy-global ls -lha /data/caddy/certificates/
```

### **Testar Configuração**

```bash
docker exec caddy-global caddy validate --config /etc/caddy/Caddyfile
```

---

## 🐛 Troubleshooting

### **Erro 525 (SSL Handshake Failed)**

**Causa:** Container Caddy duplicado ou conflito de porta

**Solução:**
```bash
# Ver containers rodando
docker ps | grep caddy

# Parar containers duplicados
docker stop <container_id>
docker rm <container_id>

# Restart do Caddy global
cd /root/caddy
docker-compose restart
```

### **Token Cloudflare Inválido**

**Verificar:**
```bash
curl -s "https://api.cloudflare.com/client/v4/user/tokens/verify" \
  -H "Authorization: Bearer SEU_TOKEN_AQUI" | jq .
```

**Reconfigurar:**
```bash
cd /root/caddy
echo 'CLOUDFLARE_API_TOKEN=novo_token_aqui' > .env
chmod 600 .env
docker-compose restart
```

### **Certificado Não Renovando**

**Verificar logs:**
```bash
docker logs caddy-global | grep -E 'certificate|renew|error'
```

**Forçar renovação:**
```bash
docker exec caddy-global rm -rf /data/caddy/certificates/*
docker-compose restart
```

### **Porta 80/443 em Uso**

**Verificar:**
```bash
netstat -tlnp | grep -E ':80|:443'
```

**Liberar:**
```bash
# Identificar processo
lsof -i :80
lsof -i :443

# Parar processo
kill -9 <PID>
```

---

## ☁️ Cloudflare

### **Configuração DNS**

| Tipo | Nome | Destino | Proxy | TTL |
|------|------|---------|-------|-----|
| A | debrief | 82.25.92.217 | ✅ Proxied | Auto |
| A | wpp | 82.25.92.217 | ✅ Proxied | Auto |

**Importante:**
- ✅ **Proxy ativado** (nuvem laranja 🟠)
- ✅ **SSL/TLS:** Full (strict)
- ✅ **Always Use HTTPS:** On

### **Configurações SSL/TLS**

Dashboard Cloudflare → SSL/TLS:
- **Mode:** Full (strict)
- **Edge Certificates:** On
- **Always Use HTTPS:** On
- **HTTP Strict Transport Security (HSTS):** On
- **Minimum TLS Version:** 1.2
- **Opportunistic Encryption:** On
- **TLS 1.3:** On
- **Automatic HTTPS Rewrites:** On

---

## ✅ Checklist de Configuração

- [x] Token Cloudflare criado com permissão DNS Edit
- [x] Token configurado em `/root/caddy/.env`
- [x] Docker Compose atualizado com imagem Cloudflare DNS
- [x] Caddyfile configurado com `dns cloudflare`
- [x] Sites configurados em `/root/caddy/sites/`
- [x] Container antigo removido
- [x] Certificados obtidos via DNS Challenge
- [x] HTTPS funcionando em todos os domínios
- [x] Renovação automática configurada
- [x] Cloudflare proxy ativado
- [x] DNS apontando para VPS (82.25.92.217)

---

## 📊 Status Final

```
✅ DeBrief:     https://debrief.interce.com.br  (HTTP/2 200)
✅ WPPConnect:  https://wpp.interce.com.br      (HTTP/2 200)
✅ SSL:         Let's Encrypt (Válido até 21/02/2026)
✅ Método:      DNS Challenge (Cloudflare)
✅ Container:   caddy-global (Healthy)
✅ Portas:      80, 443
```

---

## 📚 Referências

- [Caddy DNS Challenge](https://caddyserver.com/docs/automatic-https#dns-challenge)
- [Cloudflare API Tokens](https://developers.cloudflare.com/fundamentals/api/get-started/create-token/)
- [Caddy Cloudflare DNS Plugin](https://github.com/caddy-dns/cloudflare)
- [Let's Encrypt](https://letsencrypt.org/)

---

**Configurado por:** Cursor AI + Alex Santos  
**Data:** 23/11/2025  
**Última verificação:** 23/11/2025 20:53:00 BRT
