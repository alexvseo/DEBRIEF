# 🔧 Corrigir Banco de Dados no Servidor - AGORA

## ❌ Problema Atual

O backend está tentando conectar em `localhost:5432` mas falha:
```
connection to server at "localhost" (::1), port 5432 failed: Connection refused
```

## ✅ Solução Rápida

Execute estes comandos **DIRETAMENTE NO SERVIDOR**:

```bash
# 1. Ir para o diretório
cd /root/debrief

# 2. Atualizar código do Git
git pull

# 3. Verificar se a mudança foi aplicada
grep DATABASE_URL docker-compose.yml

# Deve mostrar: host.docker.internal:5432 (NÃO localhost:5432)

# 4. Se ainda mostrar localhost, aplicar correção manual:
sed -i 's|localhost:5432|host.docker.internal:5432|g' docker-compose.yml

# 5. RECRIAR o container (importante: não apenas restart)
docker-compose down backend
docker-compose up -d backend

# 6. Aguardar 15 segundos
sleep 15

# 7. Verificar logs
docker-compose logs --tail=20 backend | grep -E "banco|database|Connection|ERROR|✅"
```

## 🔍 Verificar se Funcionou

Após executar os comandos acima, verifique:

```bash
# Ver logs recentes
docker-compose logs --tail=30 backend

# Procurar por:
# ✅ Sem mensagens de "Connection refused"
# ✅ Backend conectou ao banco (sem avisos de banco)
```

## ⚠️ Se Ainda Não Funcionar

### Opção 1: Verificar se PostgreSQL está rodando

```bash
systemctl status postgresql
netstat -tlnp | grep 5432
```

### Opção 2: Testar conexão do container

```bash
docker exec debrief-backend python -c "
import os
from sqlalchemy import create_engine, text

db_url = os.getenv('DATABASE_URL')
print(f'DATABASE_URL: {db_url}')

try:
    engine = create_engine(db_url)
    with engine.connect() as conn:
        result = conn.execute(text('SELECT 1 as test'))
        print('✅ Conexão funcionou!')
except Exception as e:
    print(f'❌ Erro: {e}')
"
```

### Opção 3: Verificar IP do docker0

```bash
# Ver IP da interface docker0
ip addr show docker0 | grep 'inet '

# Se host.docker.internal não funcionar, usar o IP do docker0
# Exemplo: 172.17.0.1
# Atualizar docker-compose.yml com esse IP
```

## 📋 Comandos Completos (Copy-Paste)

```bash
cd /root/debrief && \
git pull && \
sed -i 's|localhost:5432|host.docker.internal:5432|g' docker-compose.yml && \
docker-compose down backend && \
docker-compose up -d backend && \
sleep 15 && \
docker-compose logs --tail=30 backend
```

