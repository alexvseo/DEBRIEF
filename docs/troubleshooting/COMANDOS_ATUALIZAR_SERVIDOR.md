# 🚀 Comandos para Atualizar o Servidor

## ⚡ Comando Rápido (Recomendado)

```bash
cd /root/debrief && git pull origin main && docker-compose restart frontend
```

## 📋 Opções Disponíveis

### Opção 1: Script Automatizado (Mais Completo)

```bash
cd /root/debrief
git pull origin main
./scripts/deploy/atualizar-servidor.sh
```

**O que faz:**
- ✅ Faz git pull
- ✅ Reconstrui imagens Docker
- ✅ Reinicia containers
- ✅ Verifica saúde dos serviços
- ✅ Mostra logs

### Opção 2: Atualização Rápida (Apenas Frontend)

```bash
cd /root/debrief
git pull origin main
docker-compose restart frontend
```

**Use quando:** Apenas o frontend foi alterado

### Opção 3: Atualização Completa (Backend + Frontend)

```bash
cd /root/debrief
git pull origin main
docker-compose down
docker-compose build --no-cache
docker-compose up -d
```

**Use quando:** Backend ou configurações Docker foram alteradas

### Opção 4: Atualização com docker-compose.host-network.yml

```bash
cd /root/debrief
git pull origin main
docker-compose down
docker-compose -f docker-compose.host-network.yml build --no-cache
docker-compose -f docker-compose.host-network.yml up -d
```

**Use quando:** Precisa garantir `network_mode: host` para PostgreSQL

## 🔍 Verificar Status Após Atualização

```bash
# Ver status dos containers
docker-compose ps

# Ver logs do backend
docker-compose logs --tail=50 backend

# Ver logs do frontend
docker-compose logs --tail=50 frontend

# Testar API
curl http://localhost:8000/api/health
```

## ⚠️ Comandos Úteis Adicionais

### Verificar se há mudanças locais

```bash
cd /root/debrief
git status
```

### Descartar mudanças locais antes de atualizar

```bash
cd /root/debrief
git checkout -- .
git reset --hard HEAD
git pull origin main
```

### Rebuild completo (limpar tudo)

```bash
cd /root/debrief
docker-compose down
docker system prune -f
docker-compose build --no-cache
docker-compose up -d
```

---

**💡 Dica:** Para atualização rápida após mudanças no frontend, use a **Opção 2**.

