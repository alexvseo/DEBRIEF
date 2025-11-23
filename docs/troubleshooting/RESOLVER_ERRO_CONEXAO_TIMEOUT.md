# 🔧 Resolver Erro: ERR_CONNECTION_TIMED_OUT

## ❌ Problema

Não é possível acessar: `http://82.25.92.217:2022/`
Erro: `ERR_CONNECTION_TIMED_OUT`

## 🔍 Possíveis Causas

1. **Porta 2022 não está aberta no firewall**
2. **Caddy não está rodando**
3. **Containers não estão iniciados**
4. **Firewall do servidor bloqueando a porta**

---

## ✅ Solução Passo a Passo

### 1. Verificar Status dos Containers

Execute no servidor:

```bash
ssh root@82.25.92.217
cd /root/debrief
docker-compose ps
```

**Esperado:**
- `debrief-caddy`: Up (healthy)
- `debrief-backend`: Up (healthy)
- `debrief-frontend`: Up (healthy)

### 2. Verificar se Porta 2022 Está Aberta

```bash
netstat -tlnp | grep 2022
```

**Deve mostrar:** algo como `0.0.0.0:2022` ou `:::2022`

### 3. Verificar Firewall (UFW)

```bash
# Ver status do firewall
ufw status

# Se a porta 2022 não estiver liberada:
ufw allow 2022/tcp
ufw allow 2025/tcp
ufw reload
```

### 4. Verificar Logs do Caddy

```bash
docker-compose logs --tail=30 caddy
```

Procure por erros ou avisos.

### 5. Reiniciar Containers

```bash
cd /root/debrief
docker-compose restart
sleep 10
docker-compose ps
```

### 6. Testar Conectividade Local

```bash
# No servidor, testar localmente:
curl http://localhost:2022

# Deve retornar HTML do frontend
```

---

## 🚀 Solução Rápida (Script Automatizado)

Execute do seu computador:

```bash
./scripts/deploy/verificar-servidor-completo.sh
```

Este script verifica tudo automaticamente.

---

## 🔧 Correções Comuns

### Problema 1: Firewall Bloqueando

```bash
# No servidor:
ufw allow 2022/tcp
ufw allow 2025/tcp
ufw reload
```

### Problema 2: Containers Não Estão Rodando

```bash
cd /root/debrief
docker-compose up -d
docker-compose ps
```

### Problema 3: Caddy Não Está Escutando

```bash
# Verificar Caddyfile
cat Caddyfile

# Reiniciar Caddy
docker-compose restart caddy

# Ver logs
docker-compose logs -f caddy
```

### Problema 4: Porta Já em Uso

```bash
# Verificar o que está usando a porta 2022
lsof -i :2022

# Se necessário, parar processo
kill <PID>
```

---

## 📋 Checklist de Verificação

Execute no servidor e verifique cada item:

```bash
# 1. Containers rodando
docker-compose ps | grep -E "Up|healthy"

# 2. Porta 2022 aberta
netstat -tlnp | grep 2022

# 3. Firewall permitindo
ufw status | grep 2022

# 4. Caddy respondendo localmente
curl -I http://localhost:2022

# 5. Backend respondendo
curl http://localhost:2025/health
```

---

## 🆘 Se Nada Funcionar

### Opção 1: Reconstruir Tudo

```bash
cd /root/debrief
docker-compose down
docker-compose build --no-cache
docker-compose up -d
sleep 30
docker-compose ps
```

### Opção 2: Verificar Configuração do Caddy

```bash
# Ver Caddyfile
cat Caddyfile

# Validar configuração
docker exec debrief-caddy caddy validate --config /etc/caddy/Caddyfile
```

### Opção 3: Verificar Logs Completos

```bash
# Todos os logs
docker-compose logs

# Apenas erros
docker-compose logs | grep -i error
```

---

## 📞 Informações para Diagnóstico

Se ainda não funcionar, execute e compartilhe:

```bash
cd /root/debrief

# Status completo
docker-compose ps
netstat -tlnp | grep -E "2022|2025"
ufw status
docker-compose logs --tail=50 caddy
docker-compose logs --tail=30 backend
```

---

## ✅ Após Corrigir

Teste novamente:
- Frontend: http://82.25.92.217:2022
- Backend: http://82.25.92.217:2025/api/docs

