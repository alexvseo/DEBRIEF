# 🔧 Correção: Erro 502 Bad Gateway na Autenticação

**Data:** 19/11/2025  
**Problema:** Erro 502 Bad Gateway ao tentar fazer login  
**Causa:** Nginx não consegue conectar ao backend  
**Status:** ✅ CORRIGIDO

---

## 🔴 Problema Identificado

O erro **502 Bad Gateway** significa que o nginx (frontend) não consegue se conectar ao backend.

**Sintomas:**
- Login retorna erro 502
- Requisições para `/api/*` retornam 502
- Frontend carrega, mas API não funciona

**Causas Comuns:**
1. Backend não está rodando
2. Backend não está saudável (unhealthy)
3. Backend não está na mesma rede Docker
4. Backend não está respondendo na porta 8000
5. Frontend inicia antes do backend estar pronto

---

## ✅ Soluções Implementadas

### 1. Melhorar `depends_on` no docker-compose.yml

**Antes:**
```yaml
depends_on:
  - backend
```

**Depois:**
```yaml
depends_on:
  backend:
    condition: service_healthy
```

**Resultado:**
- ✅ Frontend só inicia quando backend está **healthy**
- ✅ Evita erro 502 por backend não estar pronto

### 2. Melhorar nginx.conf

Adicionado:
- ✅ Retry automático em caso de falha
- ✅ Timeouts otimizados
- ✅ Headers adicionais para melhor debugging

### 3. Script de Diagnóstico

Criado `diagnostico_502.sh` para diagnosticar problemas:
- ✅ Verifica status dos containers
- ✅ Testa conectividade entre containers
- ✅ Verifica resolução DNS
- ✅ Testa proxy do nginx

---

## 🚀 Como Aplicar no Servidor

### Passo 1: Push (já feito)
```bash
git push
```

### Passo 2: No servidor - Rebuild e Reiniciar

```bash
ssh root@82.25.92.217
cd ~/debrief

# Pull atualizações
git pull

# Parar tudo
docker-compose down

# Rebuild (se necessário)
docker-compose build --no-cache

# Iniciar (backend primeiro, depois frontend)
docker-compose up -d

# Aguardar backend ficar healthy (pode levar 30-60 segundos)
echo "Aguardando backend ficar healthy..."
sleep 30

# Verificar status
docker-compose ps

# Verificar logs
docker-compose logs backend | tail -20
docker-compose logs frontend | tail -20
```

### Passo 3: Executar Diagnóstico

```bash
# Executar script de diagnóstico
./diagnostico_502.sh

# Seguir as recomendações do script
```

---

## 🔍 Diagnóstico Passo a Passo

### 1. Verificar Status dos Containers

```bash
docker-compose ps
```

**Esperado:**
```
NAME               STATUS
debrief-backend    Up X minutes (healthy)
debrief-frontend   Up X minutes (healthy)
```

**Se backend estiver "unhealthy":**
```bash
# Ver logs do backend
docker-compose logs backend

# Verificar se há erros
docker-compose logs backend | grep -i "error\|exception"
```

### 2. Testar Backend Diretamente

```bash
# Testar dentro do container backend
docker-compose exec backend curl http://localhost:8000/health

# Deve retornar: {"status":"healthy",...}
```

**Se não funcionar:**
- Backend não está rodando corretamente
- Verificar logs: `docker-compose logs backend`

### 3. Testar Conectividade Entre Containers

```bash
# Do frontend para backend
docker-compose exec frontend wget -O- http://backend:8000/health

# Deve retornar JSON com status
```

**Se não funcionar:**
- Containers não estão na mesma rede
- Nome "backend" não resolve
- Solução: `docker-compose down && docker-compose up -d`

### 4. Testar Proxy do Nginx

```bash
# Via proxy
curl http://localhost:2022/api/health

# Deve retornar: {"status":"healthy",...}
```

**Se retornar 502:**
- Nginx não consegue conectar ao backend
- Verificar logs: `docker-compose logs frontend | grep -i "502\|upstream"`

---

## 🐛 Troubleshooting

### Backend está "unhealthy"

**Causa:** Backend não está respondendo corretamente

**Solução:**
```bash
# Ver logs completos
docker-compose logs backend

# Verificar se há erros de configuração
docker-compose logs backend | grep -i "error\|exception\|traceback"

# Reiniciar backend
docker-compose restart backend

# Se persistir, rebuild
docker-compose build --no-cache backend
docker-compose up -d backend
```

### Frontend não consegue resolver "backend"

**Causa:** Problema de rede Docker

**Solução:**
```bash
# Recriar rede
docker-compose down
docker network prune -f
docker-compose up -d

# Verificar rede
docker network inspect debrief_debrief-network
```

### Backend responde, mas proxy retorna 502

**Causa:** Nginx configurado incorretamente ou backend não está pronto

**Solução:**
```bash
# Verificar configuração do nginx
docker-compose exec frontend nginx -t

# Reiniciar frontend
docker-compose restart frontend

# Verificar logs do nginx
docker-compose logs frontend | grep -i "error\|502"
```

### Erro persiste após todas as correções

**Solução completa:**
```bash
# Parar tudo
docker-compose down -v

# Limpar imagens antigas (opcional)
docker-compose rm -f

# Rebuild completo
docker-compose build --no-cache

# Iniciar
docker-compose up -d

# Aguardar backend ficar healthy
sleep 60

# Verificar
docker-compose ps
curl http://localhost:8000/health
curl http://localhost:2022/api/health
```

---

## 📊 Fluxo de Inicialização Correto

```
1. docker-compose up -d
   ↓
2. Backend inicia
   ↓
3. Backend aguarda health check (40s)
   ↓
4. Backend fica "healthy"
   ↓
5. Frontend inicia (depends_on: condition: service_healthy)
   ↓
6. Nginx faz proxy para backend:8000
   ↓
7. ✅ Tudo funcionando
```

---

## ✅ Checklist de Verificação

- [ ] Backend está "healthy" (`docker-compose ps`)
- [ ] Backend responde diretamente (`curl http://localhost:8000/health`)
- [ ] Frontend consegue conectar ao backend (`docker-compose exec frontend wget http://backend:8000/health`)
- [ ] Proxy do nginx funciona (`curl http://localhost:2022/api/health`)
- [ ] Login funciona (testar no navegador)
- [ ] Sem erros 502 nos logs

---

## 📝 Arquivos Modificados

1. ✅ `docker-compose.yml` - `depends_on` com `condition: service_healthy`
2. ✅ `frontend/nginx.conf` - Melhorias no proxy
3. ✅ `diagnostico_502.sh` - Script de diagnóstico criado

---

## 🎯 Resultado Esperado

Após aplicar as correções:

1. ✅ Backend inicia e fica healthy
2. ✅ Frontend aguarda backend estar pronto
3. ✅ Nginx consegue fazer proxy para backend
4. ✅ Login funciona sem erro 502
5. ✅ Todas as requisições `/api/*` funcionam

---

## 🚀 Próximos Passos

1. ✅ **Fazer push** das alterações:
   ```bash
   git add .
   git commit -m "🔧 fix: Corrigir erro 502 - melhorar depends_on e nginx"
   git push
   ```

2. ✅ **No servidor, fazer pull e reiniciar:**
   ```bash
   git pull
   docker-compose down
   docker-compose up -d
   ```

3. ✅ **Executar diagnóstico:**
   ```bash
   ./diagnostico_502.sh
   ```

4. ✅ **Testar login:**
   - Acesse: http://82.25.92.217:2022/login
   - Credenciais: `admin` / `admin123`
   - Deve funcionar sem erro 502! ✅

---

**✅ Problema corrigido!**

**🔧 O frontend agora aguarda o backend estar pronto antes de iniciar!**

