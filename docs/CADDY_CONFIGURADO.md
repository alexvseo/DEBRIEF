# 🚀 Configuração com Caddy - DeBrief

**Data:** 19/11/2025  
**Status:** ✅ CONFIGURADO

---

## 🎯 Objetivo

Migrar de Nginx para Caddy como proxy reverso, mantendo:
- **Frontend:** Porta 2022 (via Caddy)
- **Backend:** Porta 2025 (acesso direto) + proxy via Caddy em /api

---

## 📊 Arquitetura

```
Cliente (Navegador)
    ↓
Caddy (Porta 2022)
    ├── /api/* → Backend:8000
    └── /* → Frontend:80
    ↓
Backend (Porta 2025 - acesso direto também disponível)
Frontend (Nginx interno)
```

---

## 📝 Arquivos Criados/Modificados

### 1. **docker-compose.yml**

**Mudanças:**
- ✅ Adicionado serviço `caddy`
- ✅ Frontend não expõe porta externa (apenas `expose: 80`)
- ✅ Caddy expõe porta 2022
- ✅ Backend mantém porta 2025 para acesso direto
- ✅ Todos os serviços na mesma rede `debrief-network`

**Estrutura:**
```yaml
services:
  backend:
    ports:
      - "2025:8000"  # Acesso direto à API
    
  frontend:
    expose:
      - "80"  # Apenas interno, Caddy faz proxy
    
  caddy:
    ports:
      - "2022:80"  # Proxy reverso
    depends_on:
      - frontend
      - backend
```

### 2. **Caddyfile**

**Configuração:**
- ✅ Escuta na porta 80 (dentro do container)
- ✅ Proxy `/api/*` para `debrief-backend:8000`
- ✅ Proxy `/*` para `debrief-frontend:80`
- ✅ Compressão automática (zstd, gzip)
- ✅ Headers de proxy configurados
- ✅ Logs para stdout

---

## 🚀 Como Aplicar no Servidor

### Passo 1: Push (já feito)
```bash
git push
```

### Passo 2: No Servidor - Atualizar e Reiniciar

```bash
ssh root@82.25.92.217
cd ~/debrief

# Pull atualizações
git pull

# Parar containers antigos
docker-compose down

# Rebuild (se necessário)
docker-compose build --no-cache

# Iniciar com Caddy
docker-compose up -d

# Aguardar backend ficar healthy
echo "Aguardando backend iniciar (2 minutos)..."
sleep 120

# Verificar status
docker-compose ps

# Verificar logs do Caddy
docker-compose logs caddy
```

### Passo 3: Testar

```bash
# Testar frontend via Caddy
curl http://localhost:2022/

# Testar API via Caddy
curl http://localhost:2022/api/health

# Testar backend direto (porta 2025)
curl http://localhost:2025/health
```

---

## 🔍 Verificações

### 1. Verificar Containers

```bash
docker-compose ps
```

**Esperado:**
```
NAME               STATUS
debrief-backend   Up X minutes (healthy)
debrief-frontend  Up X minutes (healthy)
debrief-caddy     Up X minutes
```

### 2. Testar Caddy

```bash
# Validar configuração do Caddy
docker-compose exec caddy caddy validate --config /etc/caddy/Caddyfile

# Ver logs
docker-compose logs caddy

# Testar proxy
curl http://localhost:2022/api/health
curl http://localhost:2022/
```

### 3. Verificar Rotas

```bash
# API via Caddy (proxy)
curl http://82.25.92.217:2022/api/health

# Frontend via Caddy
curl http://82.25.92.217:2022/

# Backend direto (porta 2025)
curl http://82.25.92.217:2025/health
```

---

## 📊 Portas Configuradas

| Serviço | Porta Externa | Porta Interna | Acesso |
|---------|---------------|---------------|--------|
| **Caddy** | 2022 | 80 | Proxy reverso |
| **Backend** | 2025 | 8000 | API direta + via Caddy |
| **Frontend** | - | 80 | Via Caddy apenas |
| **PostgreSQL** | 5432 | 5432 | Banco de dados |

---

## 🔄 Fluxo de Requisições

### Requisição para Frontend:
```
Cliente → http://82.25.92.217:2022/login
    ↓
Caddy (porta 2022)
    ↓
Frontend:80 (Nginx interno)
    ↓
React App
```

### Requisição para API via Caddy:
```
Cliente → http://82.25.92.217:2022/api/auth/login
    ↓
Caddy (porta 2022) → /api/*
    ↓
Backend:8000
    ↓
FastAPI
```

### Requisição para API Direta:
```
Cliente → http://82.25.92.217:2025/api/auth/login
    ↓
Backend:8000 (porta 2025 mapeada)
    ↓
FastAPI
```

---

## ✅ Vantagens do Caddy

1. ✅ **Configuração Simples:** Caddyfile é mais simples que nginx.conf
2. ✅ **HTTPS Automático:** Caddy pode gerar certificados SSL automaticamente
3. ✅ **Compressão Automática:** zstd e gzip configurados automaticamente
4. ✅ **Logs Estruturados:** Logs em formato JSON ou console
5. ✅ **Menos Configuração:** Headers e timeouts configurados automaticamente

---

## 🔧 Configuração do Caddyfile

### Estrutura:
```caddy
:80 {
    # Compressão
    encode zstd gzip

    # Proxy para API
    @api {
        path /api/*
    }
    handle @api {
        reverse_proxy debrief-backend:8000
    }

    # Proxy para Frontend
    handle {
        reverse_proxy debrief-frontend:80
    }

    # Logs
    log {
        output stdout
    }
}
```

---

## 🐛 Troubleshooting

### Caddy não inicia

```bash
# Validar Caddyfile
docker-compose exec caddy caddy validate --config /etc/caddy/Caddyfile

# Ver logs
docker-compose logs caddy

# Verificar se arquivo está montado
docker-compose exec caddy ls -la /etc/caddy/
```

### Proxy não funciona

```bash
# Verificar se serviços estão rodando
docker-compose ps

# Testar conectividade do Caddy para backend
docker-compose exec caddy wget -O- http://debrief-backend:8000/health

# Testar conectividade do Caddy para frontend
docker-compose exec caddy wget -O- http://debrief-frontend:80/
```

### Erro 502 Bad Gateway

```bash
# Verificar logs do Caddy
docker-compose logs caddy | grep -i "502\|error"

# Verificar se backend está healthy
docker-compose ps backend

# Verificar se frontend está healthy
docker-compose ps frontend
```

---

## 🔒 Configuração de Firewall

### UFW (Ubuntu/Debian)

```bash
# Permitir porta 2022 (Caddy)
ufw allow 2022/tcp

# Permitir porta 2025 (Backend direto)
ufw allow 2025/tcp

# Verificar
ufw status
```

### Firewalld (CentOS/RHEL)

```bash
# Permitir portas
firewall-cmd --permanent --add-port=2022/tcp
firewall-cmd --permanent --add-port=2025/tcp
firewall-cmd --reload

# Verificar
firewall-cmd --list-ports
```

---

## 📝 Migração de Nginx para Caddy

### O que mudou:

1. **Frontend:**
   - ❌ Antes: Expunha porta 2022 diretamente
   - ✅ Agora: Expõe apenas porta 80 interna, Caddy faz proxy

2. **Backend:**
   - ✅ Mantido: Porta 2025 para acesso direto
   - ✅ Adicionado: Proxy via Caddy em `/api`

3. **Proxy:**
   - ❌ Antes: Nginx dentro do container frontend
   - ✅ Agora: Caddy como serviço separado

### Benefícios:

- ✅ Separação de responsabilidades
- ✅ Caddy mais simples de configurar
- ✅ Melhor para escalabilidade futura
- ✅ HTTPS automático (quando configurado)

---

## ✅ Checklist de Verificação

- [ ] Caddyfile criado e configurado
- [ ] docker-compose.yml atualizado
- [ ] Push feito para GitHub
- [ ] Pull feito no servidor
- [ ] Containers reiniciados
- [ ] Caddy rodando
- [ ] Frontend acessível via Caddy (porta 2022)
- [ ] API acessível via Caddy (/api)
- [ ] Backend acessível diretamente (porta 2025)
- [ ] Firewall configurado
- [ ] Logs do Caddy verificados

---

## 🚀 Próximos Passos

1. ✅ **Fazer push** das alterações:
   ```bash
   git add .
   git commit -m "🚀 feat: Migrar para Caddy como proxy reverso"
   git push
   ```

2. ✅ **No servidor, atualizar:**
   ```bash
   git pull
   docker-compose down
   docker-compose build --no-cache
   docker-compose up -d
   ```

3. ✅ **Testar:**
   - Frontend: http://82.25.92.217:2022
   - API via Caddy: http://82.25.92.217:2022/api/health
   - Backend direto: http://82.25.92.217:2025/health

---

**✅ Caddy configurado como proxy reverso!**

**🚀 Sistema agora usa Caddy ao invés de Nginx interno!**

