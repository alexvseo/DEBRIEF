# 🐍 DeBrief Backend - FastAPI

Backend da aplicação DeBrief - Sistema de Gestão de Demandas e Briefings

## 🚀 Tecnologias

- **FastAPI** 0.110.0 - Framework web moderno e rápido
- **SQLAlchemy** 2.0.27 - ORM para Python
- **PostgreSQL** - Banco de dados relacional
- **Pydantic** 2.6.1 - Validação de dados
- **JWT** - Autenticação com tokens
- **Bcrypt** - Hash de senhas
- **Uvicorn** - Servidor ASGI

---

## 📁 Estrutura do Projeto

```
backend/
├── app/
│   ├── api/
│   │   └── endpoints/
│   │       ├── auth.py          # Autenticação
│   │       └── demandas.py      # CRUD demandas
│   ├── core/
│   │   ├── config.py            # Configurações
│   │   ├── database.py          # Conexão DB
│   │   ├── security.py          # JWT e senhas
│   │   └── dependencies.py      # Dependências FastAPI
│   ├── models/
│   │   ├── base.py              # Modelo base
│   │   ├── user.py              # Modelo User
│   │   └── demanda.py           # Modelo Demanda
│   ├── schemas/
│   │   ├── user.py              # Schemas User
│   │   └── demanda.py           # Schemas Demanda
│   └── main.py                  # Aplicação principal
├── requirements.txt             # Dependências
├── .env                         # Variáveis ambiente
└── README.md                    # Este arquivo
```

---

## 🔧 Instalação

### 1. Instalar Dependências

```bash
# Criar ambiente virtual (recomendado)
python -m venv venv

# Ativar ambiente virtual
# Windows:
venv\Scripts\activate
# Linux/Mac:
source venv/bin/activate

# Instalar dependências
pip install -r requirements.txt
```

### 2. Configurar PostgreSQL

```bash
# Instalar PostgreSQL (se não tiver)
# Mac:
brew install postgresql
brew services start postgresql

# Linux (Ubuntu/Debian):
sudo apt-get install postgresql postgresql-contrib
sudo service postgresql start

# Criar banco de dados
psql -U postgres
CREATE DATABASE debrief;
CREATE USER debrief WITH PASSWORD 'debrief123';
GRANT ALL PRIVILEGES ON DATABASE debrief TO debrief;
\q
```

### 3. Configurar Variáveis de Ambiente

O arquivo `.env` já foi criado com valores padrão.

Para produção, edite:
```bash
SECRET_KEY=seu-secret-super-seguro-aqui
DEBUG=False
DATABASE_URL=postgresql://user:pass@host:5432/dbname
```

---

## 🚀 Executar

### Modo Desenvolvimento

```bash
# Com uvicorn (hot reload)
uvicorn app.main:app --reload --host 0.0.0.0 --port 8000

# Ou usando Python
python -m app.main
```

### Modo Produção

```bash
# Com gunicorn (múltiplos workers)
gunicorn app.main:app --workers 4 --worker-class uvicorn.workers.UvicornWorker --bind 0.0.0.0:8000
```

---

## 📚 Documentação da API

Após iniciar o servidor, acesse:

- **Swagger UI**: http://localhost:8000/api/docs
- **ReDoc**: http://localhost:8000/api/redoc
- **OpenAPI JSON**: http://localhost:8000/api/openapi.json

---

## 🔐 Endpoints de Autenticação

### POST /api/auth/login
Login de usuário (OAuth2 compatible)

```bash
curl -X POST "http://localhost:8000/api/auth/login" \
  -H "Content-Type: application/x-www-form-urlencoded" \
  -d "username=admin&password=admin123"
```

Resposta:
```json
{
  "access_token": "eyJhbGc...",
  "token_type": "bearer",
  "user": {
    "id": "...",
    "username": "admin",
    "email": "admin@debrief.com",
    "nome_completo": "Administrador",
    "tipo": "master"
  }
}
```

### GET /api/auth/me
Obter perfil do usuário autenticado

```bash
curl -X GET "http://localhost:8000/api/auth/me" \
  -H "Authorization: Bearer {token}"
```

### PUT /api/auth/me
Atualizar perfil do usuário

```bash
curl -X PUT "http://localhost:8000/api/auth/me" \
  -H "Authorization: Bearer {token}" \
  -H "Content-Type: application/json" \
  -d '{"nome_completo": "Novo Nome"}'
```

### POST /api/auth/register
Registrar novo usuário

```bash
curl -X POST "http://localhost:8000/api/auth/register" \
  -H "Content-Type: application/json" \
  -d '{
    "username": "novouser",
    "email": "novo@email.com",
    "password": "senha123",
    "nome_completo": "Novo Usuário"
  }'
```

---

## 📋 Endpoints de Demandas

### POST /api/demandas
Criar nova demanda

```bash
curl -X POST "http://localhost:8000/api/demandas" \
  -H "Authorization: Bearer {token}" \
  -H "Content-Type: application/json" \
  -d '{
    "nome": "Nova Demanda",
    "descricao": "Descrição detalhada",
    "prioridade": "alta",
    "tipo_demanda_id": "...",
    "prazo_final": "2025-12-31"
  }'
```

### GET /api/demandas
Listar demandas do usuário

```bash
curl -X GET "http://localhost:8000/api/demandas?skip=0&limit=20" \
  -H "Authorization: Bearer {token}"
```

### GET /api/demandas/{id}
Obter demanda por ID

```bash
curl -X GET "http://localhost:8000/api/demandas/{id}" \
  -H "Authorization: Bearer {token}"
```

### PUT /api/demandas/{id}
Atualizar demanda

```bash
curl -X PUT "http://localhost:8000/api/demandas/{id}" \
  -H "Authorization: Bearer {token}" \
  -H "Content-Type: application/json" \
  -d '{
    "status": "em_andamento",
    "prioridade": "urgente"
  }'
```

### DELETE /api/demandas/{id}
Deletar demanda (apenas master)

```bash
curl -X DELETE "http://localhost:8000/api/demandas/{id}" \
  -H "Authorization: Bearer {token}"
```

### GET /api/demandas/stats/summary
Obter estatísticas de demandas

```bash
curl -X GET "http://localhost:8000/api/demandas/stats/summary" \
  -H "Authorization: Bearer {token}"
```

---

## 🗄️ Modelos de Dados

### User
```python
{
  "id": "uuid",
  "username": "string (3-50 chars, único)",
  "email": "string (email, único)",
  "nome_completo": "string (3-200 chars)",
  "tipo": "master | cliente",
  "cliente_id": "uuid (opcional)",
  "ativo": "boolean",
  "created_at": "datetime",
  "updated_at": "datetime"
}
```

### Demanda
```python
{
  "id": "uuid",
  "nome": "string (5-200 chars)",
  "descricao": "string (10-2000 chars)",
  "status": "aberta | em_andamento | aguardando_cliente | concluida | cancelada",
  "prioridade": "baixa | media | alta | urgente",
  "prazo_final": "date (opcional)",
  "data_conclusao": "datetime (opcional)",
  "usuario_id": "uuid",
  "tipo_demanda_id": "uuid",
  "secretaria_id": "uuid (opcional)",
  "created_at": "datetime",
  "updated_at": "datetime"
}
```

---

## 🔒 Segurança

### JWT Tokens
- Algoritmo: HS256
- Expiração: 24 horas (padrão)
- Incluem: user_id, username, tipo

### Senhas
- Hash: Bcrypt
- Custo: Padrão (ajustável)
- Verificação automática de rehash

### Permissões
- **Master**: Acesso total
- **Cliente**: Acesso apenas às próprias demandas

---

## 🧪 Testes

### Criar Usuário de Teste

```python
from app.models.user import User
from app.core.database import SessionLocal

db = SessionLocal()

user = User(
    username="admin",
    email="admin@debrief.com",
    nome_completo="Administrador Master",
    tipo="master"
)
user.set_password("admin123")

db.add(user)
db.commit()
```

---

## 🐛 Troubleshooting

### Erro de conexão com PostgreSQL
```bash
# Verificar se PostgreSQL está rodando
sudo service postgresql status  # Linux
brew services list              # Mac

# Verificar se banco existe
psql -U postgres -l
```

### Erro de importação
```bash
# Reinstalar dependências
pip install --upgrade -r requirements.txt
```

### Erro de migração
```bash
# Recriar banco
python -c "from app.core.database import init_db; init_db()"
```

---

## 📝 Próximos Passos

- [ ] Adicionar Alembic para migrations
- [ ] Implementar refresh tokens
- [ ] Adicionar endpoints de recuperação de senha
- [ ] Implementar upload de arquivos
- [ ] Integrar Trello API
- [ ] Integrar WPPConnect (WhatsApp)
- [ ] Adicionar testes unitários
- [ ] Adicionar Docker
- [ ] Configurar CI/CD

---

## 📄 Licença

Este projeto é privado e proprietário.

---

## 👥 Contato

Para dúvidas e suporte, entre em contato com a equipe de desenvolvimento.

---

**Desenvolvido com ❤️ usando FastAPI** 🚀

