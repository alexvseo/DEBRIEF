# 🔧 Resolver Conexão do Container com Banco

## ❌ Problema

O container backend não consegue conectar ao banco de dados. O teste travou ao tentar conectar.

## 🔍 Diagnóstico

Execute no servidor:

```bash
ssh root@82.25.92.217
cd /root/debrief
git pull
./scripts/deploy/testar-conexao-container.sh
```

## ✅ Soluções Possíveis

### Solução 1: Verificar host.docker.internal

```bash
# Testar se funciona
docker exec debrief-backend ping -c 2 host.docker.internal

# Se não funcionar, usar IP do docker0
ip addr show docker0 | grep 'inet '
# Exemplo: 172.17.0.1
```

### Solução 2: Usar IP do docker0

Se `host.docker.internal` não funcionar:

```bash
# 1. Obter IP do docker0
DOCKER_IP=$(ip addr show docker0 | grep 'inet ' | awk '{print $2}' | cut -d/ -f1)
echo "IP do docker0: $DOCKER_IP"

# 2. Atualizar docker-compose.yml
sed -i "s|host.docker.internal:5432|$DOCKER_IP:5432|g" docker-compose.yml

# 3. Recriar backend
docker-compose stop backend
docker-compose rm -f backend
docker-compose up -d backend
```

### Solução 3: Usar network_mode: host

Alternativa: fazer backend usar rede do host:

```bash
# Editar docker-compose.yml
nano docker-compose.yml

# Adicionar na seção backend:
network_mode: host

# E remover:
# - extra_hosts
# - networks: debrief-network

# Recriar
docker-compose up -d backend
```

### Solução 4: Configurar PostgreSQL para aceitar conexões remotas

```bash
# Editar postgresql.conf
nano /etc/postgresql/*/main/postgresql.conf
# Alterar: listen_addresses = '*'

# Editar pg_hba.conf
nano /etc/postgresql/*/main/pg_hba.conf
# Adicionar: host    dbrief    postgres    172.17.0.0/16    md5

# Reiniciar PostgreSQL
systemctl restart postgresql
```

## 🧪 Teste Rápido

```bash
# Testar conexão com timeout
timeout 10 docker exec debrief-backend python3 -c "
import os
from sqlalchemy import create_engine, text
db_url = os.getenv('DATABASE_URL')
engine = create_engine(db_url, connect_args={'connect_timeout': 5})
with engine.connect() as conn:
    result = conn.execute(text('SELECT 1'))
    print('✅ OK:', result.fetchone())
"
```

## 📋 Checklist

- [ ] host.docker.internal está acessível?
- [ ] Porta 5432 está acessível do container?
- [ ] DATABASE_URL está correto?
- [ ] PostgreSQL está escutando?
- [ ] Firewall permite conexão?

