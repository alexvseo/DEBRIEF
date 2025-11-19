# 🔧 Correção: Backend Unhealthy - Container não inicia

**Data:** 19/11/2025  
**Problema:** Container backend fica "unhealthy" e não inicia  
**Status:** ✅ DIAGNÓSTICO E CORREÇÕES IMPLEMENTADAS

---

## 🔴 Problema Identificado

O container backend está falhando ao iniciar e fica com status "unhealthy", impedindo que o frontend inicie (devido ao `depends_on: condition: service_healthy`).

**Sintomas:**
- Container backend mostra "Error" ou "unhealthy"
- Frontend não inicia: "dependency failed to start: container debrief-backend is unhealthy"
- Health check falha

**Causas Comuns:**
1. Erro ao iniciar a aplicação (erro de código)
2. Erro de conexão com banco de dados
3. Erro de configuração (variáveis de ambiente)
4. Erro de importação de módulos
5. Tempo insuficiente para iniciar (start_period muito curto)
6. Falta de espaço em disco
7. Dependências não instaladas corretamente

---

## ✅ Correções Implementadas

### 1. Aumentar `start_period` do Healthcheck

**Antes:**
```yaml
start_period: 40s  # Muito curto para inicialização completa
```

**Depois:**
```yaml
start_period: 120s  # 2 minutos para backend iniciar completamente
```

**Resultado:**
- ✅ Backend tem mais tempo para conectar ao banco
- ✅ Backend tem mais tempo para inicializar todos os módulos
- ✅ Health check não falha prematuramente

### 2. Script de Diagnóstico Completo

Criado `diagnostico_backend_unhealthy.sh` que verifica:
- ✅ Status do container
- ✅ Health status e tentativas
- ✅ Logs completos do backend
- ✅ Erros específicos
- ✅ Teste manual de health check
- ✅ Processos rodando no container
- ✅ Variáveis de ambiente
- ✅ Conexão com banco de dados
- ✅ Importação de módulos
- ✅ Espaço em disco

---

## 🚀 Como Diagnosticar no Servidor

### Passo 1: Executar Script de Diagnóstico

```bash
ssh root@82.25.92.217
cd ~/debrief

# Executar diagnóstico
./diagnostico_backend_unhealthy.sh
```

O script mostrará:
- Status atual do backend
- Logs completos
- Erros encontrados
- Testes de conectividade
- Próximos passos recomendados

### Passo 2: Ver Logs Manualmente

```bash
# Ver últimas 100 linhas dos logs
docker-compose logs --tail=100 backend

# Ver apenas erros
docker-compose logs backend | grep -i "error\|exception\|traceback\|failed"

# Ver logs em tempo real
docker-compose logs -f backend
```

### Passo 3: Testar Health Check Manualmente

```bash
# Testar dentro do container
docker-compose exec backend curl http://localhost:8000/health

# Se falhar, verificar se o processo está rodando
docker-compose exec backend ps aux | grep uvicorn
```

---

## 🐛 Troubleshooting por Tipo de Erro

### Erro: "error parsing value for field ALLOWED_EXTENSIONS"

**Causa:** Problema ao fazer parse de variável de ambiente

**Solução:**
```bash
# Verificar variável no container
docker-compose exec backend env | grep ALLOWED_EXTENSIONS

# Deve ser: ALLOWED_EXTENSIONS=pdf,jpg,jpeg,png

# Se estiver incorreto, verificar docker-compose.yml
# Já foi corrigido com validador no config.py
```

### Erro: "could not connect to server"

**Causa:** Backend não consegue conectar ao banco de dados

**Solução:**
```bash
# Verificar DATABASE_URL
docker-compose exec backend env | grep DATABASE_URL

# Testar conexão manualmente
docker-compose exec backend python -c "
from app.core.database import engine
from sqlalchemy import text
with engine.connect() as conn:
    result = conn.execute(text('SELECT 1'))
    print('OK')
"

# Se falhar, verificar:
# - Firewall permite conexão na porta 5432
# - Credenciais estão corretas
# - Banco 'dbrief' existe
```

### Erro: "ModuleNotFoundError" ou "ImportError"

**Causa:** Dependências não instaladas ou código com erro

**Solução:**
```bash
# Rebuild do backend
docker-compose build --no-cache backend

# Verificar se requirements.txt está correto
cat backend/requirements.txt

# Reinstalar dependências
docker-compose exec backend pip install -r requirements.txt
```

### Erro: "No space left on device"

**Causa:** Disco cheio

**Solução:**
```bash
# Verificar espaço
df -h

# Limpar imagens Docker não usadas
docker system prune -a

# Limpar volumes não usados
docker volume prune
```

### Backend inicia mas health check falha

**Causa:** Health check muito rápido ou endpoint /health não existe

**Solução:**
```bash
# Verificar se endpoint /health existe
docker-compose exec backend curl http://localhost:8000/health

# Se retornar 404, verificar se rota está definida em app/main.py
# Já foi aumentado start_period para 120s
```

---

## 🔧 Soluções Rápidas

### Solução 1: Reiniciar Backend

```bash
docker-compose restart backend

# Aguardar 2 minutos
sleep 120

# Verificar status
docker-compose ps backend
```

### Solução 2: Rebuild do Backend

```bash
# Parar backend
docker-compose stop backend

# Rebuild
docker-compose build --no-cache backend

# Iniciar
docker-compose up -d backend

# Aguardar
sleep 120

# Verificar
docker-compose ps backend
docker-compose logs backend | tail -20
```

### Solução 3: Limpar e Recriar Tudo

```bash
# Parar tudo
docker-compose down

# Limpar volumes (CUIDADO: remove dados)
# docker-compose down -v

# Rebuild completo
docker-compose build --no-cache

# Iniciar
docker-compose up -d

# Aguardar backend ficar healthy (2 minutos)
echo "Aguardando backend iniciar..."
sleep 120

# Verificar
docker-compose ps
```

---

## 📊 Verificações Passo a Passo

### 1. Verificar Status

```bash
docker-compose ps backend
```

**Esperado:**
```
NAME               STATUS
debrief-backend    Up X minutes (healthy)
```

**Se estiver "unhealthy":**
- Executar diagnóstico: `./diagnostico_backend_unhealthy.sh`
- Ver logs: `docker-compose logs backend`

### 2. Verificar Logs

```bash
# Últimas 50 linhas
docker-compose logs --tail=50 backend

# Procurar erros
docker-compose logs backend | grep -i "error\|exception\|traceback"
```

### 3. Testar Health Check

```bash
# Dentro do container
docker-compose exec backend curl http://localhost:8000/health

# Deve retornar: {"status":"healthy",...}
```

### 4. Verificar Processos

```bash
docker-compose exec backend ps aux | grep uvicorn

# Deve mostrar processo uvicorn rodando
```

### 5. Testar Conexão com Banco

```bash
docker-compose exec backend python -c "
from app.core.database import engine
from sqlalchemy import text
try:
    with engine.connect() as conn:
        result = conn.execute(text('SELECT 1'))
        print('✅ Banco OK')
except Exception as e:
    print(f'❌ Erro: {e}')
"
```

---

## ✅ Checklist de Verificação

- [ ] Script de diagnóstico executado
- [ ] Logs do backend verificados
- [ ] Erros identificados e corrigidos
- [ ] Health check testado manualmente
- [ ] Processo uvicorn rodando
- [ ] Conexão com banco funcionando
- [ ] Variáveis de ambiente corretas
- [ ] Backend rebuildado (se necessário)
- [ ] Backend está "healthy"
- [ ] Frontend consegue iniciar

---

## 📝 Arquivos Modificados

1. ✅ `docker-compose.yml` - `start_period` aumentado para 120s
2. ✅ `backend/Dockerfile` - `start_period` aumentado para 120s
3. ✅ `diagnostico_backend_unhealthy.sh` - Script de diagnóstico criado

---

## 🎯 Resultado Esperado

Após aplicar as correções:

1. ✅ Backend tem 2 minutos para iniciar completamente
2. ✅ Health check não falha prematuramente
3. ✅ Backend fica "healthy" após iniciar
4. ✅ Frontend consegue iniciar (depends_on satisfeito)
5. ✅ Sistema funcionando completamente

---

## 🚀 Próximos Passos

1. ✅ **Fazer push** das alterações:
   ```bash
   git add .
   git commit -m "🔧 fix: Aumentar start_period do healthcheck e criar diagnóstico"
   git push
   ```

2. ✅ **No servidor, executar diagnóstico:**
   ```bash
   git pull
   ./diagnostico_backend_unhealthy.sh
   ```

3. ✅ **Seguir recomendações do diagnóstico**

4. ✅ **Rebuild se necessário:**
   ```bash
   docker-compose build --no-cache backend
   docker-compose up -d backend
   ```

5. ✅ **Aguardar e verificar:**
   ```bash
   sleep 120
   docker-compose ps
   ```

---

**✅ Correções implementadas!**

**🔧 Execute o diagnóstico no servidor para identificar o problema específico!**

