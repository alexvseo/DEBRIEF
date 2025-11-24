# 🔧 Alteração de Porta do Backend para 2025

**Data:** 19/11/2025  
**Alteração:** Porta externa do backend mudou de 8000 para 2025  
**Status:** ✅ CONFIGURADO

---

## 🎯 Alteração Realizada

**Porta do Backend alterada:**
- ❌ **Antes:** `8000` (externa)
- ✅ **Agora:** `2025` (externa)
- ✅ **Interna:** `8000` (mantida - dentro do container Docker)

**Porta do Frontend:**
- ✅ **Mantida:** `2022` (externa)

---

## 📊 Portas Configuradas

| Serviço | Porta Externa | Porta Interna (Container) | URL |
|---------|---------------|---------------------------|-----|
| **Frontend** | 2022 | 80 | http://82.25.92.217:2022 |
| **Backend** | 2025 | 8000 | http://82.25.92.217:2025 |
| **PostgreSQL** | 5432 | 5432 | 82.25.92.217:5432 |
| **SSH** | 22 | - | ssh root@82.25.92.217 |

---

## 📝 Arquivos Modificados

### 1. **docker-compose.yml**
```yaml
# Antes
ports:
  - "8000:8000"

# Depois
ports:
  - "2025:8000"  # Externa:Interna
```

### 2. **Scripts Atualizados**
- ✅ `docker-deploy.sh` - URLs atualizadas
- ✅ `setup-servidor.sh` - URLs atualizadas
- ✅ `diagnostico_login.sh` - Porta atualizada

### 3. **Documentação**
- ✅ Referências à porta 8000 atualizadas para 2025

---

## ⚠️ Importante: Porta Interna vs Externa

### Porta Interna (Container)
- **Mantida em 8000** dentro do container Docker
- O FastAPI continua rodando na porta 8000 internamente
- O nginx faz proxy para `backend:8000` (nome do serviço + porta interna)

### Porta Externa (Host)
- **Alterada para 2025** no host/servidor
- Acessível de fora do Docker em `http://82.25.92.217:2025`
- Mapeamento: `2025:8000` (externa:interna)

---

## 🚀 Como Aplicar no Servidor

### Passo 1: Fazer Push
```bash
git push
```

### Passo 2: No Servidor - Atualizar e Reiniciar

```bash
ssh root@82.25.92.217
cd ~/debrief

# Pull atualizações
git pull

# Parar containers
docker-compose down

# Reiniciar (porta será atualizada automaticamente)
docker-compose up -d

# Verificar status
docker-compose ps

# Testar backend na nova porta
curl http://localhost:2025/health
```

### Passo 3: Configurar Firewall

```bash
# Remover regra antiga (se existir)
ufw delete allow 8000/tcp

# Adicionar nova regra
ufw allow 2025/tcp

# Verificar
ufw status
```

---

## 🔍 Verificações

### Testar Backend na Nova Porta

```bash
# Health check
curl http://82.25.92.217:2025/health

# API Docs
curl http://82.25.92.217:2025/docs

# Login (teste)
curl -X POST http://82.25.92.217:2025/api/auth/login \
  -H "Content-Type: application/x-www-form-urlencoded" \
  -d "username=admin&password=admin123"
```

### Verificar Portas

```bash
# Ver processos usando as portas
lsof -i :2025
lsof -i :2022

# Ou com netstat
netstat -tulpn | grep :2025
netstat -tulpn | grep :2022
```

### Verificar Logs

```bash
docker-compose logs backend
docker-compose logs frontend
```

---

## 🔒 Configuração de Firewall

### UFW (Ubuntu/Debian)

```bash
# Permitir porta 2025
ufw allow 2025/tcp

# Verificar regras
ufw status numbered

# Se precisar remover regra antiga
ufw delete allow 8000/tcp
```

### Firewalld (CentOS/RHEL)

```bash
# Permitir porta 2025
firewall-cmd --permanent --add-port=2025/tcp
firewall-cmd --reload

# Verificar
firewall-cmd --list-ports
```

---

## 📊 Resumo das Alterações

### Antes:
```
Frontend: http://82.25.92.217:2022 ✅
Backend:  http://82.25.92.217:8000 ❌
```

### Depois:
```
Frontend: http://82.25.92.217:2022 ✅
Backend:  http://82.25.92.217:2025 ✅
```

---

## ✅ Checklist de Verificação

- [ ] Código atualizado no repositório
- [ ] Push feito para GitHub
- [ ] Pull feito no servidor
- [ ] Containers reiniciados
- [ ] Backend acessível em http://82.25.92.217:2025
- [ ] Frontend acessível em http://82.25.92.217:2022
- [ ] Firewall configurado (porta 2025)
- [ ] Proxy nginx funcionando (frontend → backend)
- [ ] Login funcionando

---

## 🎯 Próximos Passos

1. ✅ **Fazer push** para GitHub
2. ✅ **Pull no servidor**
3. ✅ **Reiniciar containers**
4. ✅ **Configurar firewall** (porta 2025)
5. ✅ **Testar acesso** em http://82.25.92.217:2025

---

## 📝 Notas Importantes

### Nginx Proxy
- ✅ **Não precisa alterar** - O nginx continua fazendo proxy para `backend:8000` (porta interna)
- ✅ O nome do serviço `backend` resolve para o IP do container
- ✅ A porta interna (8000) não mudou

### Acesso Direto ao Backend
- ✅ Agora acessível em: http://82.25.92.217:2025
- ✅ API Docs: http://82.25.92.217:2025/docs
- ✅ Health: http://82.25.92.217:2025/health

### Frontend
- ✅ Continua acessível em: http://82.25.92.217:2022
- ✅ Faz proxy para backend via `/api` (nginx)

---

## 🔄 Comandos Rápidos

### No Servidor:
```bash
# Atualizar código
git pull

# Reiniciar
docker-compose down && docker-compose up -d

# Configurar firewall
ufw allow 2025/tcp

# Verificar
curl http://82.25.92.217:2025/health
curl http://82.25.92.217:2022/api/health
```

---

**✅ Porta do backend alterada para 2025!**

**🚀 Execute `git push` e depois atualize no servidor!**

