# 🔧 Porta do Frontend Alterada para 2022

**Data:** 19/11/2025  
**Status:** ✅ CONFIGURADO

---

## 🎯 Alteração Realizada

**Porta do Frontend alterada:**
- ❌ **Antes:** `3000`
- ✅ **Agora:** `2022`

**URL de Acesso:**
- ✅ **Frontend:** http://82.25.92.217:2022
- ✅ **Backend:** http://82.25.92.217:8000 (inalterado)
- ✅ **Docs:** http://82.25.92.217:8000/docs (inalterado)

---

## 📝 Arquivos Modificados

### 1. **docker-compose.yml**
```yaml
# Antes
ports:
  - "3000:80"

# Depois
ports:
  - "2022:80"
```

```yaml
# Antes
- FRONTEND_URL=http://localhost:3000

# Depois
- FRONTEND_URL=http://82.25.92.217:2022
```

### 2. **backend/app/core/config.py**
```python
# Adicionado ao CORS_ORIGINS:
CORS_ORIGINS: list[str] = [
    "http://localhost:5173",
    "http://localhost:3000",
    "http://localhost:2022",  # ← NOVO
    "http://127.0.0.1:5173",
    "http://127.0.0.1:3000",
    "http://127.0.0.1:2022",  # ← NOVO
    "http://82.25.92.217:2022",  # ← NOVO (produção)
]
```

### 3. **env.docker.example**
```bash
# Antes
FRONTEND_URL=http://localhost:3000

# Depois
FRONTEND_URL=http://82.25.92.217:2022
```

### 4. **Scripts Atualizados**
- ✅ `docker-deploy.sh` - URLs atualizadas
- ✅ `setup-servidor.sh` - URLs atualizadas

### 5. **Documentação Atualizada**
- ✅ `COMANDOS_DEPLOY.md`
- ✅ `DEPLOY_SERVIDOR.md`
- ✅ `INICIO_DEPLOY.md`
- ✅ `RESUMO_FINAL_DEPLOY.md`

---

## 🚀 Como Aplicar no Servidor

### 1️⃣ Fazer Push (No seu computador)

```bash
cd /Users/alexmini/Documents/PROJETOS\ DEV\ COM\ IA/DEBRIEF
git push
```

### 2️⃣ No Servidor - Atualizar e Reiniciar

```bash
ssh root@82.25.92.217
cd ~/debrief  # ou /var/www/debrief

# Pull das atualizações
git pull

# Atualizar variável de ambiente (se necessário)
nano backend/.env
# Verificar se FRONTEND_URL está como: http://82.25.92.217:2022

# Reiniciar containers
docker-compose down
docker-compose up -d

# Verificar
docker-compose ps
docker-compose logs -f
```

### 3️⃣ Configurar Firewall

```bash
# Remover regra antiga (se existir)
ufw delete allow 3000/tcp

# Adicionar nova regra
ufw allow 2022/tcp

# Verificar
ufw status
```

---

## ✅ Verificações

### Testar Acesso

```bash
# Frontend
curl http://82.25.92.217:2022

# Backend
curl http://82.25.92.217:8000/health
```

### Verificar Portas

```bash
# Ver processos usando as portas
lsof -i :2022
lsof -i :8000

# Ou com netstat
netstat -tulpn | grep :2022
netstat -tulpn | grep :8000
```

### Verificar Logs

```bash
docker-compose logs frontend
docker-compose logs backend
```

---

## 🔒 Configuração de Firewall

### UFW (Ubuntu/Debian)

```bash
# Permitir porta 2022
ufw allow 2022/tcp

# Verificar regras
ufw status numbered

# Se precisar remover regra antiga
ufw delete allow 3000/tcp
```

### Firewalld (CentOS/RHEL)

```bash
# Permitir porta 2022
firewall-cmd --permanent --add-port=2022/tcp
firewall-cmd --reload

# Verificar
firewall-cmd --list-ports
```

---

## 📊 Resumo das Portas

| Serviço | Porta Externa | Porta Interna (Container) | URL |
|---------|---------------|---------------------------|-----|
| **Frontend** | 2022 | 80 | http://82.25.92.217:2022 |
| **Backend** | 8000 | 8000 | http://82.25.92.217:8000 |
| **PostgreSQL** | 5432 | 5432 | 82.25.92.217:5432 |
| **SSH** | 22 | - | ssh root@82.25.92.217 |

---

## 🎯 Próximos Passos

1. ✅ **Fazer push** para GitHub
2. ✅ **Pull no servidor**
3. ✅ **Reiniciar containers**
4. ✅ **Configurar firewall** (porta 2022)
5. ✅ **Testar acesso** em http://82.25.92.217:2022

---

## 📝 Notas Importantes

### CORS
- ✅ Nova URL adicionada ao `CORS_ORIGINS`
- ✅ Backend aceita requisições de http://82.25.92.217:2022
- ✅ URLs de desenvolvimento local mantidas

### Firewall
- ⚠️ **Importante:** Configurar firewall para permitir porta 2022
- ⚠️ Remover regra da porta 3000 se não for mais usada

### Variáveis de Ambiente
- ✅ `FRONTEND_URL` atualizado no `docker-compose.yml`
- ✅ Atualizar `backend/.env` no servidor se necessário

---

## 🎉 Resultado

**Frontend agora acessível em:**
```
http://82.25.92.217:2022
```

**Backend continua em:**
```
http://82.25.92.217:8000
```

---

## 🔄 Comandos Rápidos

### No Servidor:
```bash
# Atualizar código
git pull

# Reiniciar
docker-compose down && docker-compose up -d

# Configurar firewall
ufw allow 2022/tcp

# Verificar
curl http://82.25.92.217:2022
```

---

**✅ Porta alterada com sucesso!**

**🚀 Execute `git push` e depois atualize no servidor!**

