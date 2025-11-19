# 🎯 DeBrief - Sistema de Gerenciamento de Demandas

Sistema completo de gerenciamento de demandas para agências e empresas, com integração Trello, WhatsApp e dashboard analítico.

[![Status](https://img.shields.io/badge/Status-Produção-success)]()
[![Docker](https://img.shields.io/badge/Docker-Ready-blue)]()
[![License](https://img.shields.io/badge/License-Private-red)]()

---

## 📋 Sobre o Projeto

DeBrief é uma plataforma completa para gerenciamento de demandas criativas e técnicas, desenvolvida para facilitar a comunicação entre clientes e equipes de execução.

### ✨ Principais Funcionalidades

- 🔐 **Autenticação JWT** - Sistema seguro de login
- 👥 **Gestão de Usuários** - Controle de acesso Master/Cliente
- 🏢 **Múltiplos Clientes** - Isolamento de dados por cliente
- 📋 **Gestão de Demandas** - CRUD completo com status e prioridades
- 📊 **Dashboard Analítico** - Gráficos e métricas em tempo real
- 📈 **Relatórios** - Filtros avançados e exportação
- 🎨 **Tipos Personalizáveis** - Design, Desenvolvimento, Conteúdo, Vídeo
- ⚡ **Prioridades** - Sistema de níveis com cores customizáveis
- 🔔 **Notificações** - WhatsApp integrado via WPPConnect
- 📱 **Integração Trello** - Sincronização automática de cards
- 📁 **Upload de Arquivos** - Anexos para demandas
- ⚙️ **Configurações** - Painel admin completo

---

## 🚀 Stack Tecnológica

### Backend
- **Framework:** FastAPI 0.115.0
- **Database:** PostgreSQL 14
- **ORM:** SQLAlchemy 2.0
- **Migrations:** Alembic 1.14.0
- **Authentication:** JWT + Bcrypt
- **Validação:** Pydantic 2.10
- **Server:** Uvicorn

### Frontend
- **Framework:** React 18
- **Build Tool:** Vite 6.0
- **Routing:** React Router 7.1
- **Styling:** TailwindCSS 3.4
- **Forms:** React Hook Form + Zod
- **Charts:** Recharts 2.15
- **Icons:** Lucide React 0.469
- **Notifications:** Sonner 1.7

### DevOps
- **Containerização:** Docker + Docker Compose
- **Web Server:** Nginx (produção)
- **Proxy:** Nginx (reverse proxy)

### Integrações
- **Trello:** py-trello 0.20.1
- **WhatsApp:** WPPConnect (REST API)
- **Criptografia:** Cryptography 44.0.0

---

## 📂 Estrutura do Projeto

```
DEBRIEF/
├── backend/                # API FastAPI
│   ├── app/
│   │   ├── api/           # Endpoints
│   │   ├── core/          # Configurações e segurança
│   │   ├── models/        # SQLAlchemy models
│   │   ├── schemas/       # Pydantic schemas
│   │   └── services/      # Serviços (Trello, WhatsApp)
│   ├── alembic/           # Migrations
│   ├── Dockerfile
│   └── requirements.txt
│
├── frontend/              # React App
│   ├── src/
│   │   ├── components/    # Componentes React
│   │   ├── pages/         # Páginas da aplicação
│   │   ├── services/      # API services
│   │   ├── contexts/      # React contexts
│   │   └── hooks/         # Custom hooks
│   ├── Dockerfile
│   ├── nginx.conf
│   └── package.json
│
├── docker-compose.yml     # Orquestração Docker
├── docker-deploy.sh       # Script de deploy
└── docs/                  # Documentação (30+ arquivos .md)
```

---

## 🐳 Quick Start com Docker

### Pré-requisitos
- Docker instalado
- Docker Compose instalado

### 1️⃣ Configurar Variáveis
```bash
cp env.docker.example backend/.env
nano backend/.env
# Configure SECRET_KEY e ENCRYPTION_KEY
```

### 2️⃣ Iniciar
```bash
./docker-deploy.sh
# Escolha opção 1 (Iniciar aplicação)
```

### 3️⃣ Acessar
- **Frontend:** http://localhost:3000
- **Backend API:** http://localhost:8000
- **Docs:** http://localhost:8000/docs

**Login Padrão:**
- Username: `admin`
- Password: `admin123`

---

## 💻 Desenvolvimento Local

### Backend

```bash
cd backend

# Criar ambiente virtual
python3.11 -m venv venv
source venv/bin/activate  # Linux/Mac
# ou
.\venv\Scripts\activate   # Windows

# Instalar dependências
pip install -r requirements.txt

# Configurar banco de dados
# Editar backend/.env com suas credenciais PostgreSQL

# Inicializar banco
python init_db.py

# Iniciar servidor
uvicorn app.main:app --reload
```

### Frontend

```bash
cd frontend

# Instalar dependências
npm install

# Iniciar dev server
npm run dev

# Build para produção
npm run build
```

---

## 📊 Funcionalidades Detalhadas

### Para Usuários Cliente
- ✅ Criar novas demandas
- ✅ Visualizar suas demandas
- ✅ Acompanhar status em tempo real
- ✅ Upload de anexos
- ✅ Dashboard com métricas pessoais
- ✅ Gráficos de demandas

### Para Usuários Master
- ✅ Todas as funcionalidades de Cliente
- ✅ Gerenciar usuários do sistema
- ✅ Gerenciar clientes
- ✅ Gerenciar secretarias/departamentos
- ✅ Configurar tipos de demanda
- ✅ Configurar níveis de prioridade
- ✅ Configurações do sistema
- ✅ Relatórios globais
- ✅ Dashboard administrativo completo
- ✅ Configurar integrações (Trello, WhatsApp)

### Integrações

#### Trello
- Criação automática de cards
- Anexos sincronizados
- Movimentação de cards por status
- Labels e membros
- Datas de vencimento

#### WhatsApp (WPPConnect)
- Notificações de novas demandas
- Alertas de mudança de status
- Lembretes de prazo
- Envio para grupos específicos

---

## 🗄️ Banco de Dados

### Modelos Principais
1. **Users** - Usuários do sistema (Master/Cliente)
2. **Clientes** - Empresas/Órgãos clientes
3. **Secretarias** - Departamentos dos clientes
4. **TiposDemanda** - Design, Desenvolvimento, etc
5. **Prioridades** - Baixa, Média, Alta, Urgente
6. **Demandas** - Solicitações dos clientes
7. **Anexos** - Arquivos das demandas
8. **Configuracoes** - Settings do sistema

### Migrations
```bash
# Criar migration
alembic revision --autogenerate -m "descrição"

# Aplicar migrations
alembic upgrade head

# Reverter
alembic downgrade -1
```

---

## 📡 API Endpoints

### Autenticação
- `POST /api/auth/login` - Login
- `POST /api/auth/register` - Registro
- `GET /api/auth/me` - Perfil atual

### Usuários (Master)
- `GET /api/usuarios/` - Listar
- `POST /api/usuarios/` - Criar
- `GET /api/usuarios/{id}` - Buscar
- `PUT /api/usuarios/{id}` - Atualizar
- `DELETE /api/usuarios/{id}` - Desativar

### Demandas
- `GET /api/demandas` - Listar
- `POST /api/demandas` - Criar
- `GET /api/demandas/{id}` - Buscar
- `PUT /api/demandas/{id}` - Atualizar
- `DELETE /api/demandas/{id}` - Deletar

### Clientes, Secretarias, Tipos, Prioridades
- Endpoints CRUD completos para cada

**Documentação completa:** http://localhost:8000/docs

---

## 🔐 Segurança

- ✅ Senhas hasheadas com Bcrypt
- ✅ JWT tokens com expiração
- ✅ Validação de dados com Pydantic
- ✅ Soft delete (dados não são removidos)
- ✅ Criptografia de configurações sensíveis (Fernet)
- ✅ CORS configurado
- ✅ SQL Injection protegido (SQLAlchemy)
- ✅ XSS protegido (React)

---

## 📚 Documentação

### Guias Principais
- 📖 **[DOCKER_README.md](DOCKER_README.md)** - Guia completo Docker
- 🚀 **[INICIO_RAPIDO_DOCKER.md](INICIO_RAPIDO_DOCKER.md)** - Quick start
- 🐙 **[GITHUB_SETUP.md](GITHUB_SETUP.md)** - Configurar GitHub
- 🏗️ **[PROJECT_SPEC.md](PROJECT_SPEC.md)** - Especificação completa
- 🎨 **[FRONTEND_GUIDE.md](FRONTEND_GUIDE.md)** - Guia frontend
- 🔧 **[BACKEND_GUIDE.md](BACKEND_GUIDE.md)** - Guia backend

### Documentação Técnica (30+ arquivos)
Veja a pasta raiz para documentação detalhada de cada módulo.

---

## 🧪 Testes

```bash
# Backend
cd backend
pytest

# Frontend
cd frontend
npm test
```

---

## 🚢 Deploy em Produção

### Servidor Configurado
- **Host:** 82.25.92.217
- **SSH:** porta 22
- **PostgreSQL:** porta 5432
- **Database:** dbrief

### Deploy com Docker

```bash
# 1. Clonar no servidor
git clone <seu-repo>
cd DEBRIEF

# 2. Configurar
cp env.docker.example backend/.env
nano backend/.env

# 3. Iniciar
./docker-deploy.sh
```

### Sem Docker

```bash
# Backend
cd backend
source venv/bin/activate
gunicorn app.main:app --workers 4 --worker-class uvicorn.workers.UvicornWorker --bind 0.0.0.0:8000

# Frontend
cd frontend
npm run build
# Servir com Nginx
```

---

## 🔧 Configuração

### Variáveis de Ambiente Principais

```bash
# Banco de Dados
DATABASE_URL=postgresql://user:pass@host:5432/dbname

# JWT
SECRET_KEY=<gerar-nova>
ENCRYPTION_KEY=<gerar-nova>

# Trello (opcional)
TRELLO_API_KEY=
TRELLO_TOKEN=

# WhatsApp (opcional)
WPP_URL=
WPP_TOKEN=
```

---

## 📈 Performance

### Backend
- Uvicorn com workers
- Connection pooling (SQLAlchemy)
- Lazy loading otimizado
- Índices no banco

### Frontend
- Code splitting
- Lazy loading de rotas
- Memoização de componentes
- Build otimizado (Vite)

---

## 🤝 Contribuindo

1. Fork o projeto
2. Crie sua branch (`git checkout -b feature/AmazingFeature`)
3. Commit suas mudanças (`git commit -m 'Add some AmazingFeature'`)
4. Push para a branch (`git push origin feature/AmazingFeature`)
5. Abra um Pull Request

---

## 📝 Roadmap

### ✅ Concluído (v1.0)
- Sistema de autenticação
- CRUD completo
- Dashboard com gráficos
- Relatórios com filtros
- Docker completo
- Integração Trello
- Integração WhatsApp

### 🔜 Próximas Versões
- [ ] Exportação PDF/Excel
- [ ] Email notifications
- [ ] Mobile app (React Native)
- [ ] Kanban board
- [ ] Time tracking
- [ ] Comentários nas demandas
- [ ] Histórico de alterações
- [ ] API webhooks

---

## 📞 Suporte

Para dúvidas ou problemas:
1. Consulte a documentação em `/docs`
2. Verifique os logs: `docker-compose logs -f`
3. Abra uma issue no GitHub

---

## 👥 Autores

- **Equipe de Desenvolvimento** - MSL Estratégia

---

## 📄 Licença

Este projeto é privado e proprietário.

---

## 🙏 Agradecimentos

- FastAPI pela excelente framework
- React pela biblioteca poderosa
- PostgreSQL pelo banco robusto
- Docker pela facilidade de deploy
- Todas as libs open-source utilizadas

---

**✨ Desenvolvido com ❤️ por MSL Estratégia**

**🚀 Sistema DeBrief - Gerenciamento de Demandas Profissional**

