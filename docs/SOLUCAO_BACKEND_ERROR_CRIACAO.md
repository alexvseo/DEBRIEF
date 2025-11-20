# 🔧 Solução: Erro ao Criar Container debrief-backend

**Data:** 19/11/2025  
**Problema:** Container debrief-backend não cria e fica unhealthy  
**Status:** ✅ SCRIPTS DE DIAGNÓSTICO CRIADOS

---

## 🔴 Problema Identificado

O container `debrief-backend` está falhando ao ser criado e fica com status "unhealthy" ou "Error", impedindo que o frontend e caddy iniciem.

**Sintomas:**
- Container mostra "Error" ao criar
- Status "unhealthy" ou não inicia
- Frontend não inicia (depends_on falha)
- Caddy não inicia (depends_on falha)

---

## ✅ Scripts de Diagnóstico Criados

### 1. **verificar-erro-backend.sh**

Script completo que verifica:
- ✅ Status do container
- ✅ Logs completos (últimas 100 linhas)
- ✅ Erros específicos
- ✅ Health status
- ✅ Processos rodando
- ✅ Health check manual
- ✅ Variáveis de ambiente
- ✅ Tentativa de iniciar isoladamente

### 2. **debug-backend.sh**

Script que inicia backend **sem -d** para ver erros em tempo real:
- ✅ Mostra erros conforme aparecem
- ✅ Não esconde saída
- ✅ Útil para identificar problema específico

### 3. **testar-backend-local.sh**

Script que testa código antes do build:
- ✅ Verifica sintaxe Python
- ✅ Testa imports
- ✅ Verifica configuração
- ✅ Testa modelos de banco

---

## 🚀 Como Diagnosticar no Servidor

### Passo 1: Verificar Erro Específico

```bash
ssh root@82.25.92.217
cd ~/debrief

# Executar verificação completa
./verificar-erro-backend.sh
```

O script mostrará:
- Logs completos do backend
- Erros específicos encontrados
- Status do container
- Health check
- Recomendações

### Passo 2: Debug em Tempo Real

```bash
# Iniciar backend sem -d para ver erros
./debug-backend.sh

# OU manualmente:
docker-compose up backend
```

Isso mostrará os erros em tempo real conforme o backend tenta iniciar.

### Passo 3: Ver Logs Completos

```bash
# Ver todas as linhas dos logs
docker-compose logs backend

# Ver apenas erros
docker-compose logs backend | grep -i "error\|exception\|traceback\|failed"

# Ver últimas 50 linhas
docker-compose logs --tail=50 backend
```

---

## 🐛 Causas Comuns e Soluções

### 1. Erro de Importação de Módulos

**Sintoma:** `ModuleNotFoundError` ou `ImportError`

**Solução:**
```bash
# Rebuild do backend
docker-compose build --no-cache backend

# Verificar se requirements.txt está completo
cat backend/requirements.txt
```

### 2. Erro de Configuração (ALLOWED_EXTENSIONS)

**Sintoma:** `error parsing value for field ALLOWED_EXTENSIONS`

**Solução:**
- ✅ Já foi corrigido com validador
- Fazer rebuild: `docker-compose build --no-cache backend`

### 3. Erro de Conexão com Banco

**Sintoma:** `could not connect to server` ou `connection refused`

**Solução:**
```bash
# Verificar DATABASE_URL
docker-compose exec backend env | grep DATABASE_URL

# Testar conexão do servidor
psql -h 82.25.92.217 -p 5432 -U root -d dbrief

# Verificar firewall
ufw status | grep 5432
```

### 4. Erro de Sintaxe no Código

**Sintoma:** `SyntaxError` ou `IndentationError`

**Solução:**
```bash
# Testar código localmente
./testar-backend-local.sh

# Verificar se há erros
cd backend
python3 -m py_compile app/main.py
```

### 5. Dependências Faltando

**Sintoma:** `ModuleNotFoundError: No module named 'X'`

**Solução:**
```bash
# Verificar requirements.txt
cat backend/requirements.txt

# Rebuild completo
docker-compose build --no-cache backend
```

### 6. Volume Mount Causando Problema

**Sintoma:** Código local sobrescrevendo código do build

**Solução:**
- ✅ Já foi removido volume mount no docker-compose.yml
- Fazer pull e rebuild: `git pull && docker-compose build --no-cache backend`

---

## 🔧 Soluções Rápidas

### Solução 1: Rebuild Completo

```bash
# Parar tudo
docker-compose down

# Rebuild sem cache
docker-compose build --no-cache backend

# Iniciar apenas backend para ver erro
docker-compose up backend
```

### Solução 2: Usar Script de Rebuild

```bash
# Rebuild completo automatizado
./rebuild-completo.sh
```

### Solução 3: Debug Passo a Passo

```bash
# 1. Ver logs
docker-compose logs backend | tail -100

# 2. Tentar iniciar sem -d
docker-compose up backend

# 3. Ver erro específico
# (pressione Ctrl+C para parar)

# 4. Corrigir erro identificado

# 5. Rebuild
docker-compose build --no-cache backend
docker-compose up -d backend
```

---

## 📊 Verificações Passo a Passo

### 1. Verificar Status

```bash
docker-compose ps backend
```

**Se mostrar "Error" ou "Exited":**
- Ver logs: `docker-compose logs backend`

### 2. Ver Logs

```bash
# Últimas 100 linhas
docker-compose logs --tail=100 backend

# Procurar erros
docker-compose logs backend | grep -i "error\|exception\|traceback"
```

### 3. Tentar Iniciar Manualmente

```bash
# Sem -d para ver erros
docker-compose up backend
```

### 4. Verificar Código

```bash
# Testar código localmente
./testar-backend-local.sh
```

---

## ✅ Checklist de Diagnóstico

- [ ] Script de verificação executado
- [ ] Logs do backend verificados
- [ ] Erro específico identificado
- [ ] Código testado localmente
- [ ] Rebuild executado
- [ ] Backend iniciado com sucesso
- [ ] Health check passando

---

## 🚀 Próximos Passos

1. ✅ **No servidor, executar diagnóstico:**
   ```bash
   ./verificar-erro-backend.sh
   ```

2. ✅ **Se não identificar, fazer debug:**
   ```bash
   ./debug-backend.sh
   ```

3. ✅ **Verificar logs completos:**
   ```bash
   docker-compose logs backend | tail -100
   ```

4. ✅ **Aplicar solução baseada no erro identificado**

5. ✅ **Rebuild e verificar:**
   ```bash
   docker-compose build --no-cache backend
   docker-compose up -d backend
   sleep 120
   docker-compose ps
   ```

---

**✅ Scripts de diagnóstico criados!**

**🔧 Execute `./verificar-erro-backend.sh` no servidor para identificar o erro específico!**

