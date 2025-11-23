# 🚀 Aplicar network_mode: host no Servidor - AGORA

## ⚠️ Problema

O `git pull` falhou porque há mudanças locais no `docker-compose.yml` e o container ainda está usando `172.17.0.1:5432` em vez de `localhost:5432`.

## ✅ Solução Rápida

Execute no servidor:

```bash
ssh root@82.25.92.217
cd /root/debrief

# Opção 1: Usar script automático (RECOMENDADO)
chmod +x scripts/deploy/aplicar-network-host.sh
./scripts/deploy/aplicar-network-host.sh
```

## 🔧 Solução Manual

Se preferir fazer manualmente:

```bash
ssh root@82.25.92.217
cd /root/debrief

# 1. Fazer stash das mudanças locais
git stash push -m "Stash antes de aplicar network_mode: host"

# 2. Atualizar código
git pull

# 3. Verificar se network_mode está presente
grep "network_mode" docker-compose.yml

# Se NÃO estiver, aplicar manualmente:
# Editar docker-compose.yml e adicionar:
#   network_mode: host
# Logo após: container_name: debrief-backend
# E remover: ports, extra_hosts, networks

# 4. Atualizar DATABASE_URL para localhost
sed -i 's|172.17.0.1:5432|localhost:5432|g' docker-compose.yml
sed -i 's|host.docker.internal:5432|localhost:5432|g' docker-compose.yml

# 5. Verificar
grep "DATABASE_URL" docker-compose.yml

# 6. Recriar backend
docker-compose stop backend
docker-compose rm -f backend
docker-compose up -d backend

# 7. Aguardar
sleep 20

# 8. Testar conexão
timeout 15 docker exec debrief-backend python3 -c "
import os
from sqlalchemy import create_engine, text
db_url = os.getenv('DATABASE_URL')
print('DATABASE_URL:', db_url[:60])
engine = create_engine(db_url, connect_args={'connect_timeout': 10})
with engine.connect() as conn:
    result = conn.execute(text('SELECT current_database()'))
    print('✅ Conectado:', result.fetchone()[0])
"

# 9. Reiniciar Caddy
docker-compose restart caddy

# 10. Testar login
curl -X POST http://localhost:2025/api/auth/login \
  -H "Content-Type: application/x-www-form-urlencoded" \
  -d "username=admin&password=admin123"
```

## ✅ Verificar se Funcionou

1. **Container rodando:**
   ```bash
   docker-compose ps backend
   ```
   Status deve ser "Up" e healthy.

2. **Conexão com banco:**
   ```bash
   docker-compose logs backend | grep -E "banco|Connection|ERROR" | tail -10
   ```
   Não deve ter erros de conexão.

3. **Login funciona:**
   ```bash
   curl -X POST http://localhost:2025/api/auth/login \
     -H "Content-Type: application/x-www-form-urlencoded" \
     -d "username=admin&password=admin123"
   ```
   Deve retornar JSON com `access_token`.

4. **Frontend acessível:**
   - Acesse: http://82.25.92.217:2022
   - Deve carregar a página de login

## 🔍 Se Ainda Não Funcionar

Verificar logs completos:

```bash
docker-compose logs backend | tail -50
docker-compose logs caddy | tail -30
docker exec debrief-backend env | grep DATABASE_URL
```

