# 🔍 Verificar Banco de Dados - AGORA

## ✅ DATABASE_URL Está Correto

O `docker-compose.yml` já está configurado corretamente:
```
DATABASE_URL=postgresql://postgres:Mslestrategia.2025%40@host.docker.internal:5432/dbrief
```

## 🧪 Verificação Completa

Execute no servidor:

```bash
ssh root@82.25.92.217
cd /root/debrief

# Atualizar script
git pull

# Executar verificação completa
./scripts/deploy/verificar-banco-completo.sh
```

## 📋 Verificação Manual Rápida

```bash
# 1. Verificar DATABASE_URL no container
docker exec debrief-backend env | grep DATABASE_URL

# 2. Verificar se PostgreSQL está rodando
systemctl status postgresql

# 3. Testar conexão local
export PGPASSWORD="Mslestra@2025"
psql -h localhost -U postgres -d dbrief -c "SELECT 1;"

# 4. Testar conexão do container
docker exec debrief-backend python -c "
import os
from sqlalchemy import create_engine, text
db_url = os.getenv('DATABASE_URL')
engine = create_engine(db_url)
with engine.connect() as conn:
    result = conn.execute(text('SELECT current_database()'))
    print('✅ Conectado:', result.fetchone()[0])
"

# 5. Verificar logs do backend
docker-compose logs --tail=30 backend | grep -E "banco|database|Connection|ERROR"

# 6. Testar login
curl -X POST http://localhost:2025/api/auth/login \
  -H "Content-Type: application/x-www-form-urlencoded" \
  -d "username=admin&password=admin123"
```

## 🔍 O Que Verificar

1. **PostgreSQL está rodando?**
   ```bash
   systemctl status postgresql
   ```

2. **PostgreSQL está escutando na porta 5432?**
   ```bash
   netstat -tlnp | grep 5432
   ```

3. **Container consegue acessar host.docker.internal?**
   ```bash
   docker exec debrief-backend ping -c 2 host.docker.internal
   ```

4. **Backend consegue conectar ao banco?**
   ```bash
   docker-compose logs backend | grep -E "Connection|ERROR|banco"
   ```

5. **Tabelas existem no banco?**
   ```bash
   psql -h localhost -U postgres -d dbrief -c "\dt"
   ```

6. **Usuário admin existe?**
   ```bash
   psql -h localhost -U postgres -d dbrief -c "SELECT username, email, ativo FROM usuarios WHERE username='admin';"
   ```

## 🆘 Se Não Conectar

### Problema 1: host.docker.internal não funciona

```bash
# Verificar IP do docker0
ip addr show docker0 | grep 'inet '

# Usar IP direto (exemplo: 172.17.0.1)
sed -i 's|host.docker.internal:5432|172.17.0.1:5432|g' docker-compose.yml
docker-compose restart backend
```

### Problema 2: PostgreSQL não está rodando

```bash
systemctl start postgresql
systemctl enable postgresql
```

### Problema 3: Backend precisa ser recriado

```bash
docker-compose stop backend
docker-compose rm -f backend
docker-compose up -d backend
sleep 20
docker-compose logs backend
```

