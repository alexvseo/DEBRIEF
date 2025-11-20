# 🚀 Atualização Completa do Servidor

Este guia explica como atualizar completamente o servidor DeBrief com as últimas mudanças.

---

## 🎯 Método Rápido (Script Automatizado)

### Executar do seu computador:

```bash
./scripts/deploy/atualizar-servidor-completo.sh
```

O script irá:
1. ✅ Conectar ao servidor via SSH
2. ✅ Fazer `git pull` (descartando mudanças locais)
3. ✅ Parar containers existentes
4. ✅ Reconstruir imagens Docker (sem cache)
5. ✅ Iniciar containers
6. ✅ Verificar saúde dos serviços
7. ✅ Mostrar logs recentes

---

## 🔧 Método Manual (Passo a Passo)

### 1. Conectar ao servidor

```bash
ssh root@82.25.92.217
```

### 2. Navegar para o diretório

```bash
cd /root/debrief
```

### 3. Verificar status Git

```bash
git status
```

### 4. Descartar mudanças locais (se necessário)

```bash
git checkout -- .
git reset --hard HEAD
```

### 5. Fazer pull

```bash
git pull origin main
```

### 6. Parar containers

```bash
docker-compose down
```

### 7. Limpar imagens antigas (opcional)

```bash
docker system prune -f
docker rmi debrief-backend:latest debrief-frontend:latest 2>/dev/null || true
```

### 8. Reconstruir imagens

```bash
docker-compose build --no-cache
```

**⏱️ Isso pode levar 5-10 minutos na primeira vez.**

### 9. Iniciar containers

```bash
docker-compose up -d
```

### 10. Aguardar inicialização

```bash
# Aguardar 60 segundos para containers iniciarem
sleep 60
```

### 11. Verificar status

```bash
docker-compose ps
```

Todos os containers devem estar com status `Up` e `healthy`.

### 12. Verificar saúde

```bash
# Backend
curl http://localhost:8000/health

# Frontend (via Caddy)
curl -I http://localhost:2022
```

### 13. Ver logs (se necessário)

```bash
# Backend
docker-compose logs --tail=50 backend

# Frontend
docker-compose logs --tail=50 frontend

# Caddy
docker-compose logs --tail=50 caddy

# Todos os serviços
docker-compose logs -f
```

---

## 🔍 Verificação Pós-Deploy

### 1. Containers rodando

```bash
docker-compose ps
```

**Esperado:**
- `debrief-backend`: Up (healthy)
- `debrief-frontend`: Up (healthy)
- `debrief-caddy`: Up (healthy)

### 2. Testar acesso

**Frontend:**
```bash
curl http://82.25.92.217:2022
```

**Backend:**
```bash
curl http://82.25.92.217:2025/health
```

**API Docs:**
```bash
curl http://82.25.92.217:2025/api/docs
```

### 3. Testar login

Acesse no navegador:
- URL: `http://82.25.92.217:2022/login`
- Username: `admin`
- Password: `admin123`

---

## ⚠️ Problemas Comuns

### Container não inicia

```bash
# Ver logs detalhados
docker-compose logs backend

# Verificar se banco está acessível
docker exec debrief-backend python -c "from app.core.database import engine; engine.connect()"
```

### Erro de conexão com banco

```bash
# Verificar se PostgreSQL está rodando
systemctl status postgresql

# Testar conexão
psql -h localhost -U postgres -d dbrief -c "SELECT 1;"
```

### Caddy retorna 502

```bash
# Verificar logs do Caddy
docker-compose logs caddy

# Verificar se backend está saudável
curl http://localhost:8000/health
```

### Porta já em uso

```bash
# Verificar o que está usando a porta
lsof -i :2022
lsof -i :2025

# Parar processo se necessário
kill <PID>
```

---

## 📊 Comandos Úteis

### Ver logs em tempo real

```bash
docker-compose logs -f
```

### Reiniciar um serviço específico

```bash
docker-compose restart backend
docker-compose restart frontend
docker-compose restart caddy
```

### Parar tudo

```bash
docker-compose down
```

### Reconstruir apenas um serviço

```bash
docker-compose build --no-cache backend
docker-compose up -d backend
```

### Limpar tudo e recomeçar

```bash
docker-compose down -v
docker system prune -a -f
docker-compose build --no-cache
docker-compose up -d
```

---

## ✅ Checklist Pós-Deploy

- [ ] Containers estão rodando (`docker-compose ps`)
- [ ] Backend está saudável (`curl http://localhost:8000/health`)
- [ ] Frontend está acessível (`curl http://localhost:2022`)
- [ ] Login funciona no navegador
- [ ] API Docs está acessível
- [ ] Sem erros nos logs (`docker-compose logs`)

---

## 🎉 Pronto!

Após a atualização, o sistema deve estar funcionando em:
- **Frontend:** http://82.25.92.217:2022
- **Backend:** http://82.25.92.217:2025
- **API Docs:** http://82.25.92.217:2025/api/docs

