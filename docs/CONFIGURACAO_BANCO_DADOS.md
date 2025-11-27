# 🗄️ Configuração do Banco de Dados - Backend

**Sistema:** DeBrief  
**Banco:** PostgreSQL (Servidor Remoto)  
**Status:** ✅ Configurado

---

## 📊 Informações do Banco

```
Host:     82.25.92.217
Port:     5432
Database: dbrief
User:     root
Password: <redacted-db-password>
```

---

## ✅ Configuração Atual

### 1. **Backend Config (`config.py`)**

A URL do banco está configurada para apontar para o servidor remoto:

```python
DATABASE_URL: str = "postgresql://root:<redacted-legacy-password-encoded>@82.25.92.217:5432/dbrief"
```

**Nota:** O `%40` é a codificação URL do caractere `@` na senha.

### 2. **Docker Compose**

O `docker-compose.yml` já está configurado:

```yaml
environment:
  - DATABASE_URL=postgresql://root:<redacted-legacy-password-encoded>@82.25.92.217:5432/dbrief
```

### 3. **Variável de Ambiente (.env)**

Para desenvolvimento local, crie um arquivo `backend/.env`:

```bash
# Banco de Dados Remoto
DATABASE_URL=postgresql://root:<redacted-legacy-password-encoded>@82.25.92.217:5432/dbrief

# Outras configurações...
SECRET_KEY=sua-chave-secreta-aqui
ENCRYPTION_KEY=sua-chave-criptografia-aqui
FRONTEND_URL=http://82.25.92.217:2022
```

---

## 🧪 Testar Conexão

### Opção 1: Script de Teste (Recomendado)

Execute o script de teste de conexão:

```bash
cd backend
source venv/bin/activate  # Se estiver usando venv
python test_db_connection.py
```

**Resultado esperado:**
```
✅ CONEXÃO COM BANCO DE DADOS: OK
✅ Engine criado com sucesso
✅ Conectado com sucesso!
✅ Banco atual: dbrief
✅ X tabela(s) encontrada(s)
```

### Opção 2: Teste Manual via Python

```python
from app.core.database import engine
from sqlalchemy import text

# Testar conexão
with engine.connect() as conn:
    result = conn.execute(text("SELECT version();"))
    print(result.fetchone()[0])
```

### Opção 3: Teste via API

Inicie o backend e teste o endpoint de health:

```bash
# Iniciar backend
cd backend
python -m uvicorn app.main:app --reload

# Em outro terminal, testar
curl http://localhost:8000/health
```

---

## 🔧 Configuração para Desenvolvimento Local

Se quiser usar um banco local para desenvolvimento:

### 1. Criar Banco Local

```bash
# Conectar ao PostgreSQL local
psql -U postgres

# Criar banco
CREATE DATABASE debrief;

# Criar usuário (opcional)
CREATE USER debrief WITH PASSWORD 'debrief123';
GRANT ALL PRIVILEGES ON DATABASE debrief TO debrief;
```

### 2. Atualizar .env

```bash
# backend/.env
DATABASE_URL=postgresql://debrief:debrief123@localhost:5432/debrief
```

### 3. Executar Script SQL

```bash
# Importar estrutura no banco local
psql -U debrief -d debrief -f ../database_schema.sql
```

---

## 🐳 Configuração Docker

### Com Docker Compose

O `docker-compose.yml` já está configurado. Apenas execute:

```bash
docker-compose up -d
```

O backend se conectará automaticamente ao banco remoto.

### Verificar Logs

```bash
# Ver logs do backend
docker-compose logs -f backend

# Verificar se conectou
docker-compose logs backend | grep -i "database\|connection\|error"
```

---

## 🔍 Troubleshooting

### Erro: "could not connect to server"

**Causa:** Servidor PostgreSQL não está acessível.

**Soluções:**
1. Verificar se o servidor está online:
   ```bash
   ping 82.25.92.217
   ```

2. Verificar se a porta está aberta:
   ```bash
   telnet 82.25.92.217 5432
   # ou
   nc -zv 82.25.92.217 5432
   ```

3. Verificar firewall no servidor:
   ```bash
   # No servidor
   sudo ufw status
   sudo ufw allow 5432/tcp
   ```

### Erro: "authentication failed"

**Causa:** Credenciais incorretas.

**Soluções:**
1. Verificar usuário e senha no `.env`
2. Verificar se a senha está codificada corretamente (`%40` para `@`)
3. Testar conexão manual:
   ```bash
   psql -h 82.25.92.217 -p 5432 -U root -d dbrief
   ```

### Erro: "database does not exist"

**Causa:** Banco `dbrief` não foi criado.

**Soluções:**
1. Criar banco no servidor:
   ```bash
   psql -h 82.25.92.217 -p 5432 -U root -d postgres
   CREATE DATABASE dbrief;
   ```

2. Importar estrutura:
   ```bash
   psql -h 82.25.92.217 -p 5432 -U root -d dbrief -f database_schema.sql
   ```

### Erro: "relation does not exist"

**Causa:** Tabelas não foram criadas.

**Soluções:**
1. Executar script SQL:
   ```bash
   psql -h 82.25.92.217 -p 5432 -U root -d dbrief -f database_schema.sql
   ```

2. Ou usar Alembic (migrations):
   ```bash
   cd backend
   alembic upgrade head
   ```

### Erro: "timeout"

**Causa:** Conexão lenta ou servidor sobrecarregado.

**Soluções:**
1. Aumentar timeout no `database.py`:
   ```python
   engine = create_engine(
       settings.DATABASE_URL,
       pool_pre_ping=True,
       connect_args={"connect_timeout": 30}  # Aumentar para 30s
   )
   ```

2. Verificar latência:
   ```bash
   ping 82.25.92.217
   ```

---

## 📝 Verificar Configuração Atual

### Ver URL do Banco (sem senha)

```python
from app.core.config import settings

# URL será exibida sem a senha completa
print(settings.DATABASE_URL.split("@")[1] if "@" in settings.DATABASE_URL else settings.DATABASE_URL)
```

### Verificar Variáveis de Ambiente

```bash
# No Docker
docker-compose exec backend env | grep DATABASE

# Localmente
cd backend
source venv/bin/activate
python -c "from app.core.config import settings; print(settings.DATABASE_URL.split('@')[1] if '@' in settings.DATABASE_URL else 'Configurado')"
```

---

## ✅ Checklist de Verificação

- [ ] Backend configurado para servidor remoto
- [ ] Arquivo `.env` criado (se desenvolvimento local)
- [ ] Script de teste executado com sucesso
- [ ] Conexão testada e funcionando
- [ ] Tabelas criadas no banco
- [ ] Backend iniciado sem erros
- [ ] API respondendo corretamente

---

## 🚀 Próximos Passos

1. ✅ **Testar conexão:**
   ```bash
   python backend/test_db_connection.py
   ```

2. ✅ **Iniciar backend:**
   ```bash
   cd backend
   python -m uvicorn app.main:app --reload
   ```

3. ✅ **Testar API:**
   - Acesse: http://localhost:8000/docs
   - Teste login: POST `/api/auth/login`
   - Credenciais: `admin` / `admin123`

---

## 📊 Estrutura do Banco

O banco `dbrief` contém:

- **8 Tabelas:**
  - `users` - Usuários do sistema
  - `clientes` - Clientes
  - `secretarias` - Secretarias
  - `tipos_demanda` - Tipos de demanda
  - `prioridades` - Prioridades
  - `demandas` - Demandas
  - `anexos` - Anexos
  - `configuracoes` - Configurações

- **3 ENUMs:**
  - `tipousuario` (master, cliente)
  - `statusdemanda` (aberta, em_andamento, ...)
  - `tipoconfiguracao` (trello, whatsapp, ...)

---

## 🔐 Segurança

⚠️ **Importante:**
- Nunca commite o arquivo `.env` no Git
- Use variáveis de ambiente em produção
- Rotacione senhas regularmente
- Use SSL/TLS para conexões em produção (recomendado)

---

**✅ Backend configurado para se comunicar com o banco no servidor!**

**🧪 Execute `python backend/test_db_connection.py` para testar!**

