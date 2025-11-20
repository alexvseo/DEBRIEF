# 🚀 Guia de Atualização do Servidor

Este guia explica como atualizar o servidor com as últimas mudanças do repositório Git.

---

## 📋 Pré-requisitos

- Acesso SSH ao servidor (82.25.92.217)
- Git configurado no servidor
- Docker e docker-compose instalados

---

## 🔄 Método 1: Script Automatizado (Recomendado)

### Passo 1: Executar o script

```bash
./scripts/deploy/atualizar-servidor.sh
```

O script irá:
1. ✅ Conectar ao servidor via SSH
2. ✅ Fazer `git pull` (descartando mudanças locais se necessário)
3. ✅ Reconstruir imagens Docker
4. ✅ Reiniciar containers
5. ✅ Verificar saúde dos serviços
6. ✅ Mostrar logs recentes

---

## 🔧 Método 2: Manual (Passo a Passo)

### Passo 1: Conectar ao servidor

```bash
ssh root@82.25.92.217
```

### Passo 2: Navegar para o diretório do projeto

```bash
cd /root/debrief
```

### Passo 3: Verificar mudanças locais

```bash
git status
```

Se houver mudanças locais que você quer descartar:

```bash
git checkout -- .
git reset --hard HEAD
```

### Passo 4: Fazer pull do repositório

```bash
git pull origin main
```

ou

```bash
git pull origin master
```

### Passo 5: Reconstruir e reiniciar containers

```bash
# Parar containers
docker-compose down

# Reconstruir imagens (sem cache)
docker-compose build --no-cache

# Iniciar containers
docker-compose up -d
```

### Passo 6: Verificar status

```bash
# Ver status dos containers
docker-compose ps

# Ver logs do backend
docker-compose logs --tail=50 backend

# Ver logs do frontend
docker-compose logs --tail=50 frontend

# Ver logs do Caddy
docker-compose logs --tail=50 caddy
```

### Passo 7: Verificar saúde dos serviços

```bash
# Backend
curl http://localhost:8000/api/health

# Frontend (via Caddy)
curl http://localhost:2022
```

---

## 🔍 Verificação Pós-Deploy

### 1. Verificar se os containers estão rodando

```bash
docker-compose ps
```

Todos devem estar com status `Up` e `healthy`.

### 2. Verificar logs de erro

```bash
# Backend
docker-compose logs backend | grep -i error

# Frontend
docker-compose logs frontend | grep -i error

# Caddy
docker-compose logs caddy | grep -i error
```

### 3. Testar endpoints

```bash
# Health check
curl http://82.25.92.217:2022/api/health

# Login (substituir credenciais)
curl -X POST http://82.25.92.217:2022/api/auth/login \
  -H "Content-Type: application/x-www-form-urlencoded" \
  -d "username=admin&password=senha123"
```

### 4. Acessar no navegador

Abra: `http://82.25.92.217:2022`

---

## ⚠️ Troubleshooting

### Erro: "Your local changes would be overwritten by merge"

**Solução:**
```bash
git stash
git pull origin main
git stash pop  # Se quiser manter as mudanças locais
```

Ou descartar mudanças locais:
```bash
git checkout -- .
git reset --hard HEAD
git pull origin main
```

### Erro: "Container is unhealthy"

**Solução:**
```bash
# Ver logs detalhados
docker-compose logs backend

# Reiniciar container
docker-compose restart backend

# Se persistir, reconstruir
docker-compose down
docker-compose build --no-cache backend
docker-compose up -d
```

### Erro: "Port already in use"

**Solução:**
```bash
# Verificar qual processo está usando a porta
sudo lsof -i :2022
sudo lsof -i :2025
sudo lsof -i :80

# Parar processo se necessário
sudo kill -9 <PID>
```

### Erro: "Cannot connect to database"

**Solução:**
```bash
# Verificar se PostgreSQL está rodando
sudo systemctl status postgresql

# Verificar conexão
psql -U postgres -h localhost -d dbrief

# Verificar configuração no docker-compose.yml
cat docker-compose.yml | grep DATABASE_URL
```

---

## 📝 Notas Importantes

1. **Backup antes de atualizar:**
   ```bash
   # Fazer backup do banco de dados
   pg_dump -U postgres dbrief > backup_$(date +%Y%m%d_%H%M%S).sql
   ```

2. **Manter logs:**
   ```bash
   # Salvar logs antes de reiniciar
   docker-compose logs > logs_$(date +%Y%m%d_%H%M%S).txt
   ```

3. **Horário de manutenção:**
   - Preferir horários de baixo tráfego
   - Avisar usuários se necessário

---

## 🔗 Links Úteis

- **Aplicação:** http://82.25.92.217:2022
- **API Docs:** http://82.25.92.217:2022/api/docs
- **Health Check:** http://82.25.92.217:2022/api/health

---

**Última atualização:** $(date +%Y-%m-%d)

