# 🔧 Resolver Problemas de Banco e Login

## ❌ Problemas Atuais

1. Backend não conecta ao banco de dados
2. Login não funciona (erro 401)
3. APIs retornam "Não autorizado"

## ✅ Solução Completa

### Opção 1: Script Automatizado

Execute do seu computador:

```bash
./scripts/deploy/corrigir-banco-e-login.sh
```

### Opção 2: Manual (Direto no Servidor)

Execute no servidor:

```bash
ssh root@82.25.92.217
cd /root/debrief

# 1. Atualizar código
git pull

# 2. Verificar DATABASE_URL
grep DATABASE_URL docker-compose.yml

# 3. Se mostrar localhost:5432, corrigir:
sed -i 's|localhost:5432|host.docker.internal:5432|g' docker-compose.yml

# 4. Verificar PostgreSQL
systemctl status postgresql

# 5. Recriar backend (importante: não apenas restart)
docker-compose stop backend
docker-compose rm -f backend
docker-compose up -d backend

# 6. Aguardar
sleep 20

# 7. Verificar logs
docker-compose logs --tail=30 backend | grep -E "banco|database|Connection|ERROR"

# 8. Testar conexão
docker exec debrief-backend python -c "
import os
from sqlalchemy import create_engine, text
db_url = os.getenv('DATABASE_URL')
engine = create_engine(db_url)
with engine.connect() as conn:
    result = conn.execute(text('SELECT 1'))
    print('✅ Conexão OK:', result.fetchone())
"

# 9. Testar login
curl -X POST http://localhost:2025/api/auth/login \
  -H "Content-Type: application/x-www-form-urlencoded" \
  -d "username=admin&password=admin123"
```

## 🔍 Verificar se Funcionou

### 1. Backend Conectou ao Banco

```bash
docker-compose logs backend | grep -E "✅|Connection|ERROR" | tail -10
```

**Esperado:** Sem mensagens de "Connection refused"

### 2. Login Funciona

```bash
curl -X POST http://localhost:2025/api/auth/login \
  -H "Content-Type: application/x-www-form-urlencoded" \
  -d "username=admin&password=admin123"
```

**Esperado:** Retorna JSON com `access_token`

### 3. Testar no Navegador

- Acesse: http://82.25.92.217:2022/login
- Username: `admin`
- Password: `admin123`
- Deve fazer login com sucesso

## 📝 Editar e Commit no Servidor

Se precisar fazer correções direto no servidor:

```bash
# 1. Atualizar
git pull

# 2. Editar
nano docker-compose.yml

# 3. Adicionar e commitar
git add docker-compose.yml
git commit -m "🔧 fix: Correção aplicada no servidor"
git push origin main
```

Veja guia completo: `docs/EDITAR_E_COMMITAR_NO_SERVIDOR.md`

## 🆘 Se Ainda Não Funcionar

### Verificar IP do docker0

```bash
ip addr show docker0 | grep 'inet '
```

Se `host.docker.internal` não funcionar, use o IP do docker0:

```bash
# Exemplo: 172.17.0.1
sed -i 's|host.docker.internal:5432|172.17.0.1:5432|g' docker-compose.yml
docker-compose restart backend
```

### Verificar PostgreSQL

```bash
# Ver se está rodando
systemctl status postgresql

# Ver se está escutando
netstat -tlnp | grep 5432

# Testar conexão
psql -h localhost -U postgres -d dbrief -c "SELECT 1;"
```

---

## ✅ Checklist Final

- [ ] DATABASE_URL usa `host.docker.internal:5432`
- [ ] PostgreSQL está rodando
- [ ] Backend foi recriado (não apenas reiniciado)
- [ ] Logs não mostram erros de conexão
- [ ] Login retorna token
- [ ] Frontend consegue fazer login

