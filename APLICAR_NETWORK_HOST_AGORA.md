# 🔧 Aplicar network_mode: host - AGORA

## ✅ Solução Aplicada

O backend agora usa `network_mode: host` para acessar PostgreSQL em `localhost:5432` diretamente.

## 🚀 Aplicar no Servidor

Execute no servidor:

```bash
ssh root@82.25.92.217
cd /root/debrief

# 1. Atualizar código
git pull

# 2. Verificar mudanças
grep -A 5 "network_mode" docker-compose.yml

# 3. Recriar backend
docker-compose stop backend
docker-compose rm -f backend
docker-compose up -d backend

# 4. Reiniciar Caddy (para pegar nova configuração)
docker-compose restart caddy

# 5. Aguardar
sleep 20

# 6. Testar conexão
timeout 10 docker exec debrief-backend python3 -c "
import os
from sqlalchemy import create_engine, text
db_url = os.getenv('DATABASE_URL')
print('DATABASE_URL:', db_url[:60])
engine = create_engine(db_url, connect_args={'connect_timeout': 5})
with engine.connect() as conn:
    result = conn.execute(text('SELECT current_database()'))
    print('✅ Conectado:', result.fetchone()[0])
"

# 7. Testar login
curl -X POST http://localhost:2025/api/auth/login \
  -H "Content-Type: application/x-www-form-urlencoded" \
  -d "username=admin&password=admin123"
```

## 📋 O Que Mudou

**Antes:**
- Backend em rede Docker bridge
- Tentava acessar via `host.docker.internal` ou `172.17.0.1`
- Não conseguia conectar

**Depois:**
- Backend usa `network_mode: host`
- Acessa `localhost:5432` diretamente
- Funciona porque PostgreSQL está em localhost

## ✅ Verificar se Funcionou

1. **Conexão com banco:**
   ```bash
   docker-compose logs backend | grep -E "banco|Connection|ERROR" | tail -10
   ```
   Não deve ter erros de conexão.

2. **Login funciona:**
   ```bash
   curl -X POST http://localhost:2025/api/auth/login \
     -H "Content-Type: application/x-www-form-urlencoded" \
     -d "username=admin&password=admin123"
   ```
   Deve retornar JSON com `access_token`.

3. **Frontend acessível:**
   - Acesse: http://82.25.92.217:2022
   - Deve carregar a página de login

## 🔍 Se Ainda Não Funcionar

Verificar logs completos:

```bash
docker-compose logs backend | tail -50
docker-compose logs caddy | tail -30
```

