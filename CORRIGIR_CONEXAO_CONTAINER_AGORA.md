# 🔧 Corrigir Conexão do Container - AGORA

## ❌ Problema

O teste de conexão travou, indicando que o container não consegue conectar ao banco via `host.docker.internal`.

## ✅ Solução Rápida: Usar IP do docker0

Execute no servidor:

```bash
ssh root@82.25.92.217
cd /root/debrief

# 1. Obter IP do docker0
DOCKER_IP=$(ip addr show docker0 | grep 'inet ' | awk '{print $2}' | cut -d/ -f1)
echo "IP do docker0: $DOCKER_IP"

# 2. Atualizar docker-compose.yml
sed -i "s|host.docker.internal:5432|$DOCKER_IP:5432|g" docker-compose.yml

# 3. Verificar mudança
grep DATABASE_URL docker-compose.yml

# 4. Recriar backend
docker-compose stop backend
docker-compose rm -f backend
docker-compose up -d backend

# 5. Aguardar
sleep 20

# 6. Testar conexão (com timeout)
timeout 10 docker exec debrief-backend python3 -c "
import os
from sqlalchemy import create_engine, text
db_url = os.getenv('DATABASE_URL')
engine = create_engine(db_url, connect_args={'connect_timeout': 5})
with engine.connect() as conn:
    result = conn.execute(text('SELECT current_database()'))
    print('✅ Conectado:', result.fetchone()[0])
"
```

## 🔄 Alternativa: Usar network_mode: host

Se o IP do docker0 não funcionar:

```bash
# 1. Editar docker-compose.yml
nano docker-compose.yml

# 2. Na seção backend, adicionar:
network_mode: host

# 3. Remover:
#    - extra_hosts
#    - networks: debrief-network

# 4. Alterar DATABASE_URL para:
DATABASE_URL=postgresql://postgres:Mslestrategia.2025%40@localhost:5432/dbrief

# 5. Recriar
docker-compose up -d backend
```

## 🧪 Teste Rápido

```bash
# Testar com timeout
timeout 10 docker exec debrief-backend python3 -c "
import os
from sqlalchemy import create_engine, text
db_url = os.getenv('DATABASE_URL')
print('Testando:', db_url[:60])
engine = create_engine(db_url, connect_args={'connect_timeout': 5})
with engine.connect() as conn:
    print('✅ OK')
"
```

## 📋 Comando Completo (Copy-Paste)

```bash
ssh root@82.25.92.217 "cd /root/debrief && DOCKER_IP=\$(ip addr show docker0 | grep 'inet ' | awk '{print \$2}' | cut -d/ -f1) && echo \"IP: \$DOCKER_IP\" && sed -i \"s|host.docker.internal:5432|\$DOCKER_IP:5432|g\" docker-compose.yml && docker-compose stop backend && docker-compose rm -f backend && docker-compose up -d backend"
```

