# 🔧 Rebuild Completo do Docker - DeBrief

**Data:** 19/11/2025  
**Objetivo:** Limpar e reconstruir tudo do zero no servidor  
**Status:** ✅ SCRIPTS E DOCUMENTAÇÃO CRIADOS

---

## 🎯 Objetivo

Limpar completamente o ambiente Docker no servidor e reconstruir tudo do zero, removendo:
- Containers antigos
- Imagens antigas
- Volumes não usados
- Cache do Docker
- Configurações desnecessárias

---

## ✅ Otimizações Implementadas

### 1. **docker-compose.yml** - Otimizado para Produção

**Mudanças:**
- ✅ Removido volume mount de código (`./backend:/app`)
- ✅ Código agora vem apenas do build da imagem
- ✅ Evita conflitos com código local
- ✅ Mais confiável em produção

**Antes:**
```yaml
volumes:
  - ./backend/uploads:/app/uploads
  - ./backend:/app  # ❌ Causava conflitos
```

**Depois:**
```yaml
volumes:
  - ./backend/uploads:/app/uploads
  # - ./backend:/app  # ✅ Removido
```

### 2. **backend/Dockerfile** - Otimizado para Produção

**Mudanças:**
- ✅ Removido `--reload` (não necessário em produção)
- ✅ Uvicorn simples e estável
- ✅ Melhor performance

**Antes:**
```dockerfile
CMD ["uvicorn", "app.main:app", "--host", "0.0.0.0", "--port", "8000", "--reload"]
```

**Depois:**
```dockerfile
CMD ["uvicorn", "app.main:app", "--host", "0.0.0.0", "--port", "8000"]
```

### 3. **frontend/nginx.conf** - Simplificado

**Mudanças:**
- ✅ Removida configuração de proxy (Caddy faz isso)
- ✅ Nginx serve apenas arquivos estáticos
- ✅ Configuração mais limpa

---

## 🚀 Scripts Criados

### 1. **rebuild-completo.sh**

Script completo que:
- ✅ Para todos os containers
- ✅ Remove containers órfãos
- ✅ Remove imagens antigas
- ✅ Limpa volumes (opcional)
- ✅ Limpa cache (opcional)
- ✅ Faz rebuild completo
- ✅ Inicia containers
- ✅ Aguarda backend ficar healthy
- ✅ Testa endpoints
- ✅ Mostra resumo final

### 2. **limpar-servidor.sh**

Script para limpeza completa:
- ✅ Remove containers
- ✅ Remove imagens
- ✅ Remove volumes (opcional)
- ✅ Limpa cache (opcional)
- ✅ Verifica espaço liberado

---

## 📋 Como Usar no Servidor

### Opção 1: Rebuild Completo (Recomendado)

```bash
ssh root@82.25.92.217
cd ~/debrief

# Pull atualizações
git pull

# Executar rebuild completo
./rebuild-completo.sh
```

O script irá:
1. Parar todos os containers
2. Remover imagens antigas
3. Limpar volumes/cache (com confirmação)
4. Rebuild completo sem cache
5. Iniciar containers
6. Aguardar backend ficar healthy
7. Testar endpoints
8. Mostrar resumo

### Opção 2: Limpeza Manual + Rebuild

```bash
# 1. Limpar servidor
./limpar-servidor.sh

# 2. Rebuild
docker-compose build --no-cache

# 3. Iniciar
docker-compose up -d

# 4. Aguardar
sleep 120

# 5. Verificar
docker-compose ps
```

### Opção 3: Comandos Manuais

```bash
# Parar tudo
docker-compose down -v

# Remover imagens
docker rmi debrief-backend:latest debrief-frontend:latest 2>/dev/null || true

# Limpar cache
docker builder prune -f

# Rebuild
docker-compose build --no-cache

# Iniciar
docker-compose up -d

# Aguardar backend
sleep 120

# Verificar
docker-compose ps
curl http://localhost:2025/health
```

---

## 🔍 Verificações Após Rebuild

### 1. Status dos Containers

```bash
docker-compose ps
```

**Esperado:**
```
NAME               STATUS
debrief-backend    Up X minutes (healthy)
debrief-frontend   Up X minutes (healthy)
debrief-caddy      Up X minutes
```

### 2. Testar Endpoints

```bash
# Backend direto
curl http://localhost:2025/health
# Deve retornar: {"status":"healthy",...}

# Frontend via Caddy
curl http://localhost:2022/
# Deve retornar HTML

# API via Caddy
curl http://localhost:2022/api/health
# Deve retornar: {"status":"healthy",...}
```

### 3. Verificar Logs

```bash
# Backend
docker-compose logs backend | tail -30

# Frontend
docker-compose logs frontend | tail -20

# Caddy
docker-compose logs caddy | tail -20
```

---

## 🐛 Troubleshooting

### Backend ainda não inicia

```bash
# Ver logs completos
docker-compose logs backend

# Verificar se há erros
docker-compose logs backend | grep -i "error\|exception\|traceback"

# Testar manualmente
docker-compose exec backend python -c "from app.main import app; print('OK')"
```

### Erro de espaço em disco

```bash
# Verificar espaço
df -h

# Limpar mais agressivamente
docker system prune -a --volumes -f
```

### Imagens não são removidas

```bash
# Forçar remoção
docker rmi -f debrief-backend:latest debrief-frontend:latest

# Ver todas as imagens
docker images | grep debrief
```

---

## 📊 O Que Foi Removido/Otimizado

### Removido:
- ✅ Volume mount de código (`./backend:/app`)
- ✅ `--reload` do uvicorn (produção)
- ✅ Configuração de proxy do nginx (Caddy faz isso)

### Mantido:
- ✅ Volume de uploads (dados importantes)
- ✅ Volumes do Caddy (configuração)
- ✅ Health checks
- ✅ Dependências corretas

---

## ✅ Checklist de Rebuild

- [ ] Pull atualizações do Git
- [ ] Executar `./rebuild-completo.sh`
- [ ] Aguardar rebuild completar
- [ ] Verificar containers estão "healthy"
- [ ] Testar endpoints
- [ ] Verificar logs (sem erros)
- [ ] Testar login no navegador

---

## 🚀 Próximos Passos

1. ✅ **Fazer push** das alterações:
   ```bash
   git add .
   git commit -m "🔧 refactor: Otimizar Docker para produção - remover volume mount e --reload"
   git push
   ```

2. ✅ **No servidor, executar rebuild:**
   ```bash
   git pull
   ./rebuild-completo.sh
   ```

3. ✅ **Verificar se tudo funcionou:**
   - Frontend: http://82.25.92.217:2022
   - Backend: http://82.25.92.217:2025
   - Login: http://82.25.92.217:2022/login

---

**✅ Docker otimizado para produção!**

**🚀 Execute `./rebuild-completo.sh` no servidor para reconstruir tudo!**

