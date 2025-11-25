# 🎯 DeBrief - Sistema de Gerenciamento de Demandas

Sistema completo de gerenciamento de demandas para agências e empresas, com integração Trello, WhatsApp (Z-API) e dashboard analítico.

[![Status](https://img.shields.io/badge/Status-Produção-success)]()
[![Docker](https://img.shields.io/badge/Docker-Ready-blue)]()
[![License](https://img.shields.io/badge/License-Private-red)]()

---

## 📋 Índice

- [Sobre o Projeto](#-sobre-o-projeto)
- [Stack Tecnológica](#-stack-tecnológica)
- [Servidor de Produção](#-servidor-de-produção)
- [Banco de Dados](#️-banco-de-dados)
- [Integrações](#-integrações)
- [Credenciais de Acesso](#-credenciais-de-acesso)
- [Quick Start](#-quick-start)
- [Desenvolvimento Local](#-desenvolvimento-local)
- [Scripts Disponíveis](#-scripts-disponíveis)
- [Estrutura do Projeto](#-estrutura-do-projeto)
- [API Endpoints](#-api-endpoints)
- [Deploy](#-deploy-em-produção)
- [Troubleshooting](#-troubleshooting)

---

## 📋 Sobre o Projeto

DeBrief é uma plataforma completa para gerenciamento de demandas criativas e técnicas, desenvolvida para facilitar a comunicação entre clientes e equipes de execução.

### ✨ Principais Funcionalidades

- 🔐 **Autenticação JWT** - Sistema seguro de login com bcrypt
- 👥 **Gestão de Usuários** - Controle de acesso Master/Cliente
- 🏢 **Múltiplos Clientes** - Isolamento de dados por cliente
- 📋 **Gestão de Demandas** - CRUD completo com status e prioridades
- 📊 **Dashboard Analítico** - Gráficos e métricas em tempo real (Recharts)
- 📈 **Relatórios** - Filtros avançados e exportação
- 🎨 **Tipos Personalizáveis** - Design, Desenvolvimento, Conteúdo, Vídeo
- ⚡ **Prioridades** - Sistema de níveis com cores customizáveis
- 🔔 **Notificações WhatsApp** - Integrado com Z-API
- 📱 **Integração Trello** - Sincronização automática bidirecional
- 📁 **Upload de Arquivos** - Anexos para demandas
- ⚙️ **Configurações** - Painel admin completo
- 🗑️ **Soft Delete** - Dados nunca são perdidos permanentemente
- 🔄 **Sistema de Reativação** - Reativa automaticamente usuários inativos

---

## 🚀 Stack Tecnológica

### Backend
- **Framework:** FastAPI 0.115.0
- **Database:** PostgreSQL 15-alpine
- **ORM:** SQLAlchemy 2.0
- **Migrations:** Alembic 1.14.0
- **Authentication:** JWT + Bcrypt
- **Validação:** Pydantic 2.10
- **Server:** Uvicorn
- **Containerização:** Docker + Docker Compose

### Frontend
- **Framework:** React 18
- **Build Tool:** Vite 6.0
- **Routing:** React Router 7.1
- **Styling:** TailwindCSS 3.4
- **Forms:** React Hook Form + Zod
- **Charts:** Recharts 2.15
- **Icons:** Lucide React 0.469
- **Notifications:** Sonner 1.7
- **HTTP Client:** Axios

### Integrações Externas
- **Trello:** py-trello 0.20.1 (sincronização bidirecional)
- **WhatsApp:** Z-API (notificações automáticas)
- **Criptografia:** Cryptography 44.0.0 (Fernet)

---

## 🌐 Servidor de Produção

### Informações do Servidor

```yaml
IP: 82.25.92.217
SSH User: root
Diretório: /var/www/debrief
```

### URLs de Acesso

- **Frontend:** http://82.25.92.217:2022 ou http://debrief.interce.com.br
- **Backend API:** http://82.25.92.217:2023
- **Documentação API:** http://82.25.92.217:2023/docs
- **ReDoc:** http://82.25.92.217:2023/redoc

### Docker Containers

```yaml
debrief-backend:
  container_name: debrief-backend
  porta: 2023:8000
  network: debrief_debrief-network
  
debrief-frontend:
  container_name: debrief-frontend
  porta: 2022:80
  network: debrief_debrief-network
  
debrief_db:
  container_name: debrief_db
  image: postgres:15-alpine
  porta: 5432 (interna)
  ip_container: 172.19.0.2
  network: debrief_debrief-network
```

### Acesso SSH

```bash
# Acesso direto ao servidor
ssh root@82.25.92.217

# Acessar logs dos containers
ssh root@82.25.92.217 "docker logs -f debrief-backend"
ssh root@82.25.92.217 "docker logs -f debrief-frontend"

# Ver status dos containers
ssh root@82.25.92.217 "docker ps"
```

---

## 🗄️ Banco de Dados

### Configuração PostgreSQL

```yaml
Host: debrief_db (no Docker) / localhost (via túnel)
Port: 5432 (container) / 5433 (túnel SSH)
Database: dbrief
Username: postgres
Password: Mslestra@2025db
IP Container: 172.19.0.2
Network: debrief_debrief-network
```

### Conexão via Túnel SSH

O PostgreSQL **não aceita conexões remotas diretas**. Use o túnel SSH:

```bash
# Script automático (recomendado)
./conectar-banco-correto.sh

# Ou comando manual
ssh -N -L 5433:172.19.0.2:5432 root@82.25.92.217

# Testar conexão
PGPASSWORD='Mslestra@2025db' psql -h localhost -p 5433 -U postgres -d dbrief -c "SELECT COUNT(*) FROM demandas;"
```

### Gerenciar Túnel

```bash
# Ver status
./gerenciar-tunel.sh status

# Iniciar túnel
./gerenciar-tunel.sh start

# Parar túnel
./gerenciar-tunel.sh stop

# Testar conexão
./gerenciar-tunel.sh test
```

### Configuração DBeaver

```yaml
Connection Settings:
  Host: localhost
  Port: 5433  # IMPORTANTE: Não usar 5432!
  Database: dbrief
  Username: postgres
  Password: Mslestra@2025db
  
SSH Tunnel: NÃO NECESSÁRIO
(Use o script ./conectar-banco-correto.sh antes)
```

### Estrutura do Banco (14 Tabelas)

#### Tabelas Principais
```sql
-- Gestão de Usuários e Clientes
users                 # Usuários do sistema (tipo: master/cliente)
clientes              # Empresas/órgãos clientes
secretarias           # Departamentos dos clientes

-- Sistema de Demandas
demandas              # Demandas principais (campo: "nome", não "titulo")
tipos_demanda         # Tipos: Design, Desenvolvimento, Vídeo, Conteúdo
prioridades           # Níveis: Baixa, Média, Alta, Urgente
anexos                # Arquivos anexados às demandas

-- Notificações
notification_logs     # Histórico de notificações enviadas
templates_mensagens   # Templates para WhatsApp

-- Integrações
configuracoes_trello         # Configurações do Trello
configuracoes_whatsapp       # Configurações do WhatsApp/Z-API
etiquetas_trello_cliente     # Etiquetas do Trello por cliente

-- Sistema
configuracoes         # Configurações gerais do sistema
alembic_version       # Controle de migrations
```

### Variável DATABASE_URL

No arquivo `backend/.env`:

```bash
# Produção (Docker)
DATABASE_URL=postgresql://postgres:Mslestra%402025db@debrief_db:5432/dbrief

# Desenvolvimento Local (via túnel)
DATABASE_URL=postgresql://postgres:Mslestra%402025db@localhost:5433/dbrief
```

⚠️ **IMPORTANTE:** A senha contém `@`, então usa URL encoding: `%40`

---

## 🔗 Integrações

### 📱 WhatsApp - Z-API

**Status:** ✅ 100% Funcional em Produção

O sistema usa **Z-API** para envio de notificações WhatsApp (substituiu Evolution API/WPPConnect).

#### Configuração Z-API

```yaml
ZAPI_BASE_URL: https://api.z-api.io
ZAPI_INSTANCE_ID: 3EABC3821EF52114B8836EDB289F0F12
ZAPI_TOKEN: F9BFDFA1F0A75E79536CE12D
ZAPI_CLIENT_TOKEN: F47cfa53858ee4869bf3e027187aa6742S
Número Conectado: 5585996039026
```

#### Variáveis de Ambiente (.env)

```bash
# Z-API WhatsApp Configuration
ZAPI_BASE_URL=https://api.z-api.io
ZAPI_INSTANCE_ID=3EABC3821EF52114B8836EDB289F0F12
ZAPI_TOKEN=F9BFDFA1F0A75E79536CE12D
ZAPI_CLIENT_TOKEN=F47cfa53858ee4869bf3e027187aa6742S
```

#### Implementação Backend

Arquivo: `backend/app/services/whatsapp.py`

```python
# Endpoint de envio
POST {base_url}/send-text

# Headers
{
    "Content-Type": "application/json",
    "Client-Token": client_token
}

# Payload
{
    "phone": "5585996039026",
    "message": "Sua mensagem aqui"
}

# Verificar status da instância
GET {base_url}/status
```

#### Funcionalidades

- ✅ Notificação de nova demanda criada
- ✅ Notificação de demanda atualizada
- ✅ Notificação de demanda concluída
- ✅ Notificação de demanda cancelada
- ✅ Templates personalizáveis por tipo de evento
- ✅ Variáveis dinâmicas nos templates

#### Scripts de Teste

```bash
# Testar envio de mensagem
./testar-envio-whatsapp.sh

# Testar Z-API diretamente
./testar-zapi-direto.sh
```

⚠️ **IMPORTANTE:** O plano atual é TRIAL e expira em ~2 dias. Necessário upgrade para continuar usando.

#### Tipos de Eventos Suportados

```python
# Validators em backend/app/schemas/template_mensagem.py
tipos_validos = [
    "demanda_criada",
    "demanda_atualizada", 
    "demanda_concluida",
    "demanda_cancelada",
    "nova_demanda",        # Legado
    "demanda_alterada",    # Legado
    "demanda_deletada"     # Legado
]
```

### 📊 Trello - Integração Bidirecional

**Status:** ✅ Funcional

#### Funcionalidades

- ✅ Criação automática de cards ao criar demanda
- ✅ Sincronização de status (lista do Trello)
- ✅ Anexos sincronizados automaticamente
- ✅ Labels por prioridade
- ✅ Membros atribuídos
- ✅ Datas de vencimento
- ✅ Exclusão de card ao deletar demanda
- ✅ Links diretos para o card no Trello

#### Campos no Model Demanda

```python
trello_card_id: str   # ID do card no Trello
trello_card_url: str  # URL direta para o card
```

#### Configuração

As configurações do Trello ficam em `configuracoes_trello` no banco:

```sql
SELECT * FROM configuracoes_trello;
```

#### Service

Arquivo: `backend/app/services/trello.py`

```python
class TrelloService:
    def criar_card(demanda) -> dict
    def atualizar_card(demanda) -> None
    def deletar_card(demanda) -> None
    def sincronizar_status(demanda) -> None
```

---

## 🔑 Credenciais de Acesso

### Usuários Padrão do Sistema

```yaml
# Usuário Master (Administrador)
username: admin
password: admin123
tipo: master
permissões: Acesso total ao sistema

# Usuário Cliente (Exemplo)
username: alex
password: alex123
tipo: cliente
permissões: Apenas suas demandas
```

### Tipos de Usuário

#### 1. Master
- Acesso total ao sistema
- Gerencia todos os usuários
- Gerencia todos os clientes
- Gerencia secretarias, tipos, prioridades
- Vê e edita TODAS as demandas
- Acesso ao painel administrativo
- Configura integrações (Trello, WhatsApp)
- `cliente_id: NULL`

#### 2. Cliente
- Vê apenas demandas do seu cliente
- Pode criar novas demandas
- Pode editar suas próprias demandas
- Pode excluir suas próprias demandas (status: aberta/em_andamento)
- Dashboard com métricas pessoais
- `cliente_id: OBRIGATÓRIO` (FK para tabela clientes)

### Validação de Senhas

```python
# Requisitos
- Mínimo: 6 caracteres
- Máximo: 72 bytes (limite bcrypt)
- Aceita: letras, números, símbolos, maiúsculas/minúsculas
- Hash: bcrypt (gerado via set_password())
```

### Sistema de Reativação Inteligente

Ao criar usuário com username/email de um usuário inativo:
- ✅ Sistema reativa automaticamente o usuário existente
- ✅ Atualiza dados com as novas informações
- ✅ Evita duplicidade de registros
- ✅ Mantém histórico de demandas

---

## 🚀 Quick Start

### Pré-requisitos

```bash
# Verificar versões
docker --version       # >= 20.10
docker-compose --version  # >= 1.29
git --version          # >= 2.30
```

### Instalação Local (Desenvolvimento)

```bash
# 1. Clonar repositório
git clone <seu-repo>
cd DEBRIEF

# 2. Configurar variáveis de ambiente
cp env.docker.example backend/.env
nano backend/.env  # Editar credenciais

# 3. Iniciar com Docker
docker-compose up -d

# 4. Verificar containers
docker-compose ps

# 5. Acessar aplicação
# Frontend: http://localhost:3000
# Backend: http://localhost:8000
# Docs: http://localhost:8000/docs
```

### Login Inicial

```
Username: admin
Password: admin123
```

### Comandos Úteis

```bash
# Ver logs em tempo real
docker-compose logs -f

# Parar aplicação
docker-compose down

# Rebuild completo (após mudanças)
docker-compose down
docker-compose build --no-cache
docker-compose up -d

# Acessar shell do backend
docker exec -it debrief-backend bash

# Acessar PostgreSQL
docker exec -it debrief_db psql -U postgres -d dbrief
```

---

## 💻 Desenvolvimento Local

### Backend (FastAPI)

```bash
cd backend

# Criar ambiente virtual
python3.11 -m venv venv
source venv/bin/activate  # Mac/Linux
# .\venv\Scripts\activate  # Windows

# Instalar dependências
pip install -r requirements.txt

# Configurar banco (criar backend/.env)
DATABASE_URL=postgresql://postgres:password@localhost:5432/dbrief
SECRET_KEY=sua-chave-secreta-aqui
ENCRYPTION_KEY=sua-encryption-key-aqui

# Inicializar banco de dados
python init_db.py

# Popular banco com dados de exemplo
python seed_db.py

# Rodar migrations
alembic upgrade head

# Iniciar servidor de desenvolvimento
uvicorn app.main:app --reload --port 8000

# Ou usar o script
./start.sh
```

#### Estrutura Backend

```
backend/
├── app/
│   ├── api/
│   │   └── endpoints/
│   │       ├── auth.py           # Autenticação JWT
│   │       ├── usuarios.py       # Gestão de usuários
│   │       ├── clientes.py       # Gestão de clientes
│   │       ├── secretarias.py    # Secretarias/Departamentos
│   │       ├── demandas.py       # CRUD de demandas
│   │       ├── tipos_demanda.py  # Tipos de demanda
│   │       ├── prioridades.py    # Níveis de prioridade
│   │       ├── anexos.py         # Upload de arquivos
│   │       ├── dashboard.py      # Métricas e estatísticas
│   │       ├── trello.py         # Integração Trello
│   │       └── whatsapp.py       # Integração WhatsApp
│   ├── core/
│   │   ├── config.py             # Configurações gerais
│   │   ├── security.py           # JWT, Bcrypt, Fernet
│   │   └── database.py           # SQLAlchemy setup
│   ├── models/                   # SQLAlchemy models
│   ├── schemas/                  # Pydantic schemas
│   ├── services/
│   │   ├── trello.py             # Service Trello
│   │   ├── whatsapp.py           # Service WhatsApp
│   │   └── notification.py       # Service Notificações
│   └── main.py                   # FastAPI app
├── alembic/                      # Migrations
├── requirements.txt
└── Dockerfile
```

### Frontend (React)

```bash
cd frontend

# Instalar dependências
npm install

# Configurar API endpoint (criar .env)
echo "VITE_API_URL=http://localhost:8000" > .env

# Iniciar dev server
npm run dev

# Build para produção
npm run build

# Preview do build
npm run preview

# Linter
npm run lint
```

#### Estrutura Frontend

```
frontend/
├── src/
│   ├── components/
│   │   ├── Navbar.jsx           # Menu de navegação
│   │   ├── ProtectedRoute.jsx   # Proteção de rotas
│   │   ├── DemandaForm.jsx      # Formulário de demanda
│   │   ├── DemandaCard.jsx      # Card de demanda
│   │   ├── FiltrosDemandas.jsx  # Filtros avançados
│   │   └── ...
│   ├── pages/
│   │   ├── Login.jsx            # Página de login
│   │   ├── Dashboard.jsx        # Dashboard principal
│   │   ├── MinhasDemandas.jsx   # Lista de demandas
│   │   ├── NovaDemanda.jsx      # Criar demanda
│   │   ├── DemandaDetalhes.jsx  # Detalhes da demanda
│   │   ├── Usuarios.jsx         # Gestão de usuários (Master)
│   │   ├── Clientes.jsx         # Gestão de clientes (Master)
│   │   ├── Secretarias.jsx      # Gestão de secretarias (Master)
│   │   ├── TiposDemanda.jsx     # Gestão de tipos (Master)
│   │   ├── Prioridades.jsx      # Gestão de prioridades (Master)
│   │   ├── ConfigTrello.jsx     # Config Trello (Master)
│   │   └── ConfigWhatsApp.jsx   # Config WhatsApp (Master)
│   ├── services/
│   │   ├── api.js               # Axios setup
│   │   ├── auth.js              # Auth service
│   │   └── demandas.js          # Demandas service
│   ├── contexts/
│   │   └── AuthContext.jsx      # Context de autenticação
│   ├── hooks/
│   │   └── useAuth.js           # Hook de autenticação
│   └── App.jsx                  # Rotas principais
├── package.json
└── Dockerfile
```

### Rotas Protegidas

```javascript
// App.jsx
import { ProtectedRoute } from './components/ProtectedRoute'

// Rota para qualquer usuário autenticado
<Route path="/dashboard" element={
  <ProtectedRoute>
    <Dashboard />
  </ProtectedRoute>
} />

// Rota apenas para Masters
<Route path="/admin/usuarios" element={
  <ProtectedRoute requireRole="master">
    <Usuarios />
  </ProtectedRoute>
} />

// Rota com permissões específicas
<Route path="/admin/config" element={
  <ProtectedRoute requireRole="master" requiredPermissions={["admin"]}>
    <Configuracoes />
  </ProtectedRoute>
} />
```

---

## 📜 Scripts Disponíveis

O projeto possui diversos scripts organizados em categorias:

### Raiz do Projeto

```bash
# Conexão ao Banco de Dados
./conectar-banco-correto.sh         # Criar túnel SSH para banco
./gerenciar-tunel.sh                # Gerenciar túnel (start/stop/status)

# WhatsApp (Z-API)
./testar-envio-whatsapp.sh          # Testar envio de mensagem
./testar-zapi-direto.sh             # Testar API diretamente

# Deploy
./EXECUTAR-DEPLOY-SERVIDOR.sh      # Deploy no servidor produção
./COMANDOS-RAPIDOS-DEPLOY.sh        # Comandos úteis de deploy
```

### scripts/deploy/

```bash
# Deploy Principal
./scripts/deploy/deploy.sh          # Deploy completo no servidor

# Deploy Específicos
./scripts/deploy/deploy-backend.sh  # Apenas backend
./scripts/deploy/deploy-frontend.sh # Apenas frontend
./scripts/deploy/deploy-rapido.sh   # Deploy rápido sem rebuild
```

### scripts/diagnostico/

```bash
# Banco de Dados
./scripts/diagnostico/verificar-banco-usado.sh       # Qual banco está sendo usado
./scripts/diagnostico/descobrir-banco.sh             # Diagnóstico completo

# Sistema
./scripts/diagnostico/verificar-integridade-completa.sh  # Verificação geral
```

### scripts/configuracao/

```bash
# Banco de Dados
./scripts/configuracao/mudar-senha-banco.sh          # Alterar senha PostgreSQL
./scripts/configuracao/configurar-banco-completo.sh  # Setup completo do banco

# Usuários
./scripts/configuracao/criar-usuario-admin.sh        # Criar usuário admin
```

### scripts/correcao/

```bash
# Correções Específicas
./scripts/correcao/corrigir-senha-backend.sh         # Corrigir senha no backend
./scripts/correcao/resetar-senha-postgres.sh         # Resetar senha do PostgreSQL
```

---

## 📂 Estrutura do Projeto

```
DEBRIEF/
│
├── backend/                    # API FastAPI
│   ├── app/
│   │   ├── api/endpoints/     # 14 endpoints REST
│   │   ├── core/              # Config, Security, Database
│   │   ├── models/            # 15 SQLAlchemy models
│   │   ├── schemas/           # 13 Pydantic schemas
│   │   ├── services/          # Trello, WhatsApp, Notification
│   │   └── main.py            # FastAPI app
│   ├── alembic/               # Database migrations
│   ├── requirements.txt       # Python dependencies
│   ├── Dockerfile
│   └── .env                   # Variáveis de ambiente
│
├── frontend/                   # React App
│   ├── src/
│   │   ├── components/        # 14 componentes React
│   │   ├── pages/             # 16 páginas
│   │   ├── services/          # API clients
│   │   ├── contexts/          # React contexts
│   │   └── hooks/             # Custom hooks
│   ├── package.json
│   ├── Dockerfile
│   └── nginx.conf            # Nginx config
│
├── scripts/                   # Scripts organizados
│   ├── deploy/               # Scripts de deploy
│   ├── diagnostico/          # Scripts de diagnóstico
│   ├── correcao/             # Scripts de correção
│   └── configuracao/         # Scripts de configuração
│
├── docs/                      # Documentação (133 arquivos .md)
│   ├── README.md             # Índice da documentação
│   ├── DOCKER_README.md      # Guia Docker
│   ├── PROJECT_SPEC.md       # Especificação completa
│   └── ...
│
├── docker-compose.yml         # Orquestração local
├── docker-compose.prod.yml    # Orquestração produção
├── README.md                  # Este arquivo
│
└── Documentação do Sistema/
    ├── BANCO-CORRETO-CONFIGURADO.md       # Guia do banco de dados
    ├── CORRECAO-PAGINA-TEMPLATES.md       # Correção templates
    ├── INTEGRACAO-ZAPI-CONCLUIDA.md       # Integração Z-API
    ├── MELHORIAS-GERENCIAMENTO-USUARIOS.md # Sistema de usuários
    └── ... (+ 50 arquivos de documentação)
```

---

## 📡 API Endpoints

Base URL Produção: `http://82.25.92.217:2023/api`  
Base URL Local: `http://localhost:8000/api`

### Autenticação

```http
POST   /api/auth/login          # Login (retorna JWT token)
POST   /api/auth/register       # Registro de novo usuário
GET    /api/auth/me             # Dados do usuário atual
POST   /api/auth/refresh        # Renovar token
POST   /api/auth/logout         # Logout
```

### Usuários (Master only)

```http
GET    /api/usuarios/           # Listar todos os usuários
POST   /api/usuarios/           # Criar novo usuário
GET    /api/usuarios/{id}       # Buscar usuário específico
PUT    /api/usuarios/{id}       # Atualizar usuário
DELETE /api/usuarios/{id}       # Desativar usuário (soft delete)
POST   /api/usuarios/{id}/hard-delete  # Excluir permanentemente
POST   /api/usuarios/{id}/reativar     # Reativar usuário inativo
```

### Clientes (Master only)

```http
GET    /api/clientes/           # Listar todos os clientes
POST   /api/clientes/           # Criar novo cliente
GET    /api/clientes/{id}       # Buscar cliente específico
PUT    /api/clientes/{id}       # Atualizar cliente
DELETE /api/clientes/{id}       # Desativar cliente
```

### Secretarias

```http
GET    /api/secretarias/                    # Listar todas (Master)
GET    /api/secretarias/cliente/{id}        # Listar por cliente (Qualquer)
POST   /api/secretarias/                    # Criar secretaria (Master)
GET    /api/secretarias/{id}                # Buscar secretaria
PUT    /api/secretarias/{id}                # Atualizar secretaria (Master)
DELETE /api/secretarias/{id}                # Desativar secretaria (Master)
```

### Demandas

```http
GET    /api/demandas            # Listar demandas (filtradas por usuário)
POST   /api/demandas            # Criar nova demanda
GET    /api/demandas/{id}       # Buscar demanda específica
PUT    /api/demandas/{id}       # Atualizar demanda
DELETE /api/demandas/{id}       # Deletar demanda (própria ou Master)
GET    /api/demandas/minhas     # Minhas demandas
GET    /api/demandas/estatisticas  # Estatísticas de demandas
```

### Tipos de Demanda (Master only)

```http
GET    /api/tipos-demanda/      # Listar tipos
POST   /api/tipos-demanda/      # Criar tipo
GET    /api/tipos-demanda/{id}  # Buscar tipo
PUT    /api/tipos-demanda/{id}  # Atualizar tipo
DELETE /api/tipos-demanda/{id}  # Desativar tipo
```

### Prioridades (Master only)

```http
GET    /api/prioridades/        # Listar prioridades
POST   /api/prioridades/        # Criar prioridade
GET    /api/prioridades/{id}    # Buscar prioridade
PUT    /api/prioridades/{id}    # Atualizar prioridade
DELETE /api/prioridades/{id}    # Desativar prioridade
```

### Anexos

```http
GET    /api/anexos/demanda/{demanda_id}  # Listar anexos de uma demanda
POST   /api/anexos/                      # Upload de anexo
GET    /api/anexos/{id}                  # Buscar anexo
DELETE /api/anexos/{id}                  # Deletar anexo
GET    /api/anexos/{id}/download         # Download do arquivo
```

### Dashboard

```http
GET    /api/dashboard/metricas           # Métricas gerais
GET    /api/dashboard/demandas-status    # Demandas por status
GET    /api/dashboard/demandas-tipo      # Demandas por tipo
GET    /api/dashboard/demandas-prioridade # Demandas por prioridade
GET    /api/dashboard/timeline           # Timeline de demandas
```

### Trello (Master only)

```http
GET    /api/trello/config               # Buscar configuração
POST   /api/trello/config               # Salvar configuração
PUT    /api/trello/config               # Atualizar configuração
POST   /api/trello/test                 # Testar conexão
POST   /api/trello/sync/{demanda_id}    # Sincronizar demanda
```

### WhatsApp (Master only)

```http
GET    /api/whatsapp/config             # Buscar configuração
POST   /api/whatsapp/config             # Salvar configuração
PUT    /api/whatsapp/config             # Atualizar configuração
POST   /api/whatsapp/test               # Testar conexão
POST   /api/whatsapp/send               # Enviar mensagem teste
GET    /api/whatsapp/templates          # Listar templates
POST   /api/whatsapp/templates          # Criar template
PUT    /api/whatsapp/templates/{id}     # Atualizar template
DELETE /api/whatsapp/templates/{id}     # Deletar template
```

### Documentação Interativa

- **Swagger UI:** http://82.25.92.217:2023/docs
- **ReDoc:** http://82.25.92.217:2023/redoc
- **OpenAPI JSON:** http://82.25.92.217:2023/openapi.json

---

## 🚢 Deploy em Produção

### Deploy Automático (Recomendado)

```bash
# 1. No seu computador local
./EXECUTAR-DEPLOY-SERVIDOR.sh

# O script irá:
# - Conectar via SSH ao servidor
# - Fazer pull do código do GitHub
# - Rebuild dos containers Docker
# - Restart dos serviços
# - Verificar status
```

### Deploy Manual

```bash
# 1. Conectar ao servidor
ssh root@82.25.92.217

# 2. Ir para o diretório
cd /var/www/debrief

# 3. Atualizar código
git pull origin main

# 4. Rebuild e restart
docker-compose -f docker-compose.prod.yml down
docker-compose -f docker-compose.prod.yml build --no-cache
docker-compose -f docker-compose.prod.yml up -d

# 5. Verificar logs
docker-compose -f docker-compose.prod.yml logs -f

# 6. Verificar containers
docker ps
```

### Verificar Deploy

```bash
# Status dos containers
docker ps

# Logs do backend
docker logs -f debrief-backend

# Logs do frontend
docker logs -f debrief-frontend

# Logs do banco
docker logs -f debrief_db

# Testar API
curl http://82.25.92.217:2023/api/health

# Testar frontend
curl http://82.25.92.217:2022
```

### Rollback

```bash
# 1. Voltar para commit anterior
git log --oneline  # Ver commits
git reset --hard <commit-hash>

# 2. Rebuild
docker-compose -f docker-compose.prod.yml down
docker-compose -f docker-compose.prod.yml up -d --build
```

---

## 🔧 Troubleshooting

### Problemas Comuns

#### 1. Erro de Conexão com Banco de Dados

```bash
# Sintomas
OperationalError: could not connect to server

# Solução
# 1. Verificar se o container está rodando
docker ps | grep debrief_db

# 2. Ver logs do container
docker logs debrief_db

# 3. Verificar senha no .env (deve ter %40 no lugar de @)
cat backend/.env | grep DATABASE_URL

# 4. Testar conexão via túnel
./conectar-banco-correto.sh
./gerenciar-tunel.sh test
```

#### 2. Templates de Mensagens com Erro

```bash
# Sintomas
AttributeError: 'TemplateMensagem' object has no attribute 'deleted_at'

# Solução
# Já corrigido no código. Se persistir:
# 1. Verificar campos do model
grep "deleted_at" backend/app/models/template_mensagem.py

# 2. Adicionar coluna se necessário
docker exec -it debrief_db psql -U postgres -d dbrief -c "ALTER TABLE templates_mensagens ADD COLUMN IF NOT EXISTS variaveis_disponiveis TEXT;"
```

#### 3. WhatsApp não Envia Mensagens

```bash
# Sintomas
ConnectionError ou Timeout ao enviar

# Solução
# 1. Verificar variáveis de ambiente
cat backend/.env | grep ZAPI

# 2. Testar conexão com Z-API
./testar-zapi-direto.sh

# 3. Verificar plano TRIAL
# Se expirou, necessário upgrade no painel Z-API

# 4. Ver logs de erro
docker logs debrief-backend | grep whatsapp
```

#### 4. Login Não Funciona

```bash
# Sintomas
401 Unauthorized ou "Credenciais inválidas"

# Solução
# 1. Verificar se usuário existe
docker exec -it debrief_db psql -U postgres -d dbrief -c "SELECT username, tipo, ativo FROM users;"

# 2. Resetar senha do admin
docker exec -it debrief-backend python -c "
from app.models.user import User
from app.core.database import SessionLocal
db = SessionLocal()
user = db.query(User).filter(User.username == 'admin').first()
if user:
    user.set_password('admin123')
    db.commit()
    print('Senha resetada!')
db.close()
"
```

#### 5. Usuários Duplicados

```bash
# Sintomas
IntegrityError: duplicate key value violates unique constraint

# Solução
# Sistema agora reativa automaticamente usuários inativos
# Se persistir, verificar:
docker exec -it debrief_db psql -U postgres -d dbrief -c "
SELECT username, email, ativo, COUNT(*) 
FROM users 
GROUP BY username, email, ativo 
HAVING COUNT(*) > 1;
"
```

#### 6. Frontend não Carrega

```bash
# Sintomas
Tela branca ou erro 404

# Solução
# 1. Verificar se container está rodando
docker ps | grep debrief-frontend

# 2. Ver logs do Nginx
docker logs debrief-frontend

# 3. Rebuild do frontend
docker-compose -f docker-compose.prod.yml up -d --build debrief-frontend

# 4. Verificar variável de ambiente
# No container frontend, verificar se VITE_API_URL está correto
docker exec -it debrief-frontend env | grep VITE
```

#### 7. CORS Error no Frontend

```bash
# Sintomas
Access to XMLHttpRequest blocked by CORS policy

# Solução
# 1. Verificar configuração CORS no backend
cat backend/app/main.py | grep -A 10 "CORS"

# 2. Adicionar origem se necessário
# Em backend/app/main.py:
app.add_middleware(
    CORSMiddleware,
    allow_origins=["http://localhost:3000", "http://82.25.92.217:2022"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)
```

### Logs Úteis

```bash
# Ver todos os logs
docker-compose -f docker-compose.prod.yml logs -f

# Logs específicos do backend
docker logs -f debrief-backend

# Logs específicos do frontend
docker logs -f debrief-frontend

# Logs do banco de dados
docker logs -f debrief_db

# Últimas 100 linhas
docker logs --tail 100 debrief-backend

# Logs com timestamp
docker logs -f -t debrief-backend
```

### Verificações de Saúde

```bash
# 1. Containers rodando
docker ps

# 2. Rede Docker
docker network ls | grep debrief
docker network inspect debrief_debrief-network

# 3. Volumes
docker volume ls | grep debrief

# 4. Uso de recursos
docker stats

# 5. Espaço em disco
df -h

# 6. Verificar porta ocupada
lsof -i :2023  # Backend
lsof -i :2022  # Frontend
```

---

## 📚 Documentação Adicional

### Documentação Completa

Toda a documentação está em **[`docs/`](docs/)** (133 arquivos):

- **[docs/README.md](docs/README.md)** - Índice completo
- **[docs/PROJECT_SPEC.md](docs/PROJECT_SPEC.md)** - Especificação do projeto
- **[docs/DOCKER_README.md](docs/DOCKER_README.md)** - Guia Docker
- **[docs/BACKEND_GUIDE.md](docs/BACKEND_GUIDE.md)** - Guia do backend
- **[docs/FRONTEND_GUIDE.md](docs/FRONTEND_GUIDE.md)** - Guia do frontend

### Documentação do Sistema

Arquivos na raiz com detalhes técnicos:

- **BANCO-CORRETO-CONFIGURADO.md** - Guia completo do banco de dados
- **INTEGRACAO-ZAPI-CONCLUIDA.md** - Documentação da integração Z-API
- **CORRECAO-PAGINA-TEMPLATES.md** - Correções nos templates de mensagens
- **MELHORIAS-GERENCIAMENTO-USUARIOS.md** - Sistema de usuários aprimorado
- **SENHA-ATUALIZADA.md** - Histórico de mudanças de senha
- **CONFIG-DBEAVER.md** - Configuração do DBeaver
- **INICIO-RAPIDO-DBEAVER.txt** - Início rápido para DBeaver

---

## 🔐 Segurança

### Medidas Implementadas

- ✅ **Senhas Hasheadas:** Bcrypt com salt automático
- ✅ **JWT Tokens:** Autenticação stateless com expiração
- ✅ **Validação de Dados:** Pydantic schemas em todas as entradas
- ✅ **Soft Delete:** Dados nunca são perdidos permanentemente
- ✅ **Criptografia:** Configurações sensíveis criptografadas (Fernet)
- ✅ **CORS Configurado:** Apenas origens permitidas
- ✅ **SQL Injection:** Protegido via SQLAlchemy ORM
- ✅ **XSS Protection:** React escapa automaticamente
- ✅ **Validação de Senhas:** Contra banco de senhas vazadas
- ✅ **Isolamento de Dados:** Clientes não acessam dados de outros
- ✅ **Rate Limiting:** (A implementar)

### Boas Práticas

```bash
# 1. Nunca commitar .env no Git
echo "backend/.env" >> .gitignore
echo "frontend/.env" >> .gitignore

# 2. Gerar novas chaves secretas
python -c "import secrets; print(secrets.token_urlsafe(32))"

# 3. Usar variáveis de ambiente
# Nunca hardcodar credenciais no código

# 4. Fazer backup regular do banco
./scripts/deploy/backup-banco.sh

# 5. Manter dependências atualizadas
pip list --outdated
npm outdated
```

---

## 🧪 Testes

### Backend

```bash
cd backend

# Instalar dependências de teste
pip install pytest pytest-cov httpx

# Rodar todos os testes
pytest

# Testes com coverage
pytest --cov=app --cov-report=html

# Ver relatório de coverage
open htmlcov/index.html
```

### Frontend

```bash
cd frontend

# Instalar dependências de teste
npm install --save-dev @testing-library/react @testing-library/jest-dom vitest

# Rodar testes
npm test

# Testes com coverage
npm run test:coverage
```

---

## 📊 Monitoramento

### Métricas Disponíveis

```bash
# 1. Status dos containers
docker ps

# 2. Uso de recursos (CPU, RAM)
docker stats

# 3. Logs em tempo real
docker-compose -f docker-compose.prod.yml logs -f

# 4. Espaço em disco
df -h

# 5. Conexões do banco
docker exec -it debrief_db psql -U postgres -d dbrief -c "
SELECT 
    datname, 
    numbackends as connections,
    xact_commit as commits,
    xact_rollback as rollbacks
FROM pg_stat_database 
WHERE datname = 'dbrief';
"

# 6. Tamanho das tabelas
docker exec -it debrief_db psql -U postgres -d dbrief -c "
SELECT 
    tablename,
    pg_size_pretty(pg_total_relation_size(schemaname||'.'||tablename)) AS size
FROM pg_tables 
WHERE schemaname = 'public'
ORDER BY pg_total_relation_size(schemaname||'.'||tablename) DESC;
"
```

---

## 🚀 Performance

### Otimizações Implementadas

#### Backend
- ✅ Uvicorn com múltiplos workers
- ✅ Connection pooling (SQLAlchemy)
- ✅ Lazy loading otimizado
- ✅ Índices no banco de dados
- ✅ Paginação em listagens
- ✅ Cache de consultas frequentes (a implementar)

#### Frontend
- ✅ Code splitting automático (Vite)
- ✅ Lazy loading de rotas
- ✅ Memoização de componentes (React.memo)
- ✅ Build otimizado com tree-shaking
- ✅ Compressão de assets
- ✅ CDN para bibliotecas (a implementar)

### Benchmarks

```bash
# Testar performance da API
ab -n 1000 -c 10 http://82.25.92.217:2023/api/health

# Análise de bundle do frontend
cd frontend
npm run build -- --analyze
```

---

## 🤝 Contribuindo

### Workflow

```bash
# 1. Fork o projeto
# 2. Criar branch para feature
git checkout -b feature/AmazingFeature

# 3. Fazer alterações e commitar
git commit -m 'Add some AmazingFeature'

# 4. Push para o branch
git push origin feature/AmazingFeature

# 5. Abrir Pull Request
```

### Padrões de Código

#### Backend (Python)
```python
# PEP 8
# Type hints
# Docstrings

def criar_demanda(
    db: Session,
    demanda_data: DemandaCreate,
    current_user: User
) -> Demanda:
    """
    Cria uma nova demanda no sistema.
    
    Args:
        db: Sessão do banco de dados
        demanda_data: Dados da demanda
        current_user: Usuário atual
        
    Returns:
        Demanda criada
    """
    ...
```

#### Frontend (JavaScript/React)
```javascript
// ESLint + Prettier
// Componentes funcionais
// PropTypes ou TypeScript

/**
 * Componente para exibir card de demanda
 * @param {Object} props - Props do componente
 * @param {Object} props.demanda - Dados da demanda
 * @param {Function} props.onEdit - Callback de edição
 */
export const DemandaCard = ({ demanda, onEdit }) => {
  ...
}
```

---

## 📝 Changelog

### v1.0.0 - Sistema Base (Concluído)
- ✅ Sistema de autenticação JWT
- ✅ Gestão de usuários (Master/Cliente)
- ✅ CRUD completo de demandas
- ✅ Dashboard com gráficos
- ✅ Relatórios com filtros
- ✅ Integração Trello
- ✅ Integração WhatsApp (Z-API)
- ✅ Docker completo
- ✅ Deploy em produção

### v1.1.0 - Melhorias (Concluído)
- ✅ Sistema de reativação de usuários
- ✅ Exclusão permanente de usuários
- ✅ Melhorias no formulário de edição
- ✅ Templates de mensagens WhatsApp
- ✅ Sincronização bidirecional Trello
- ✅ Validações de senha robustas

### v1.2.0 - Em Desenvolvimento
- 🔄 Exportação PDF/Excel
- 🔄 Kanban board
- 🔄 Comentários nas demandas
- 🔄 Histórico de alterações
- 🔄 API webhooks
- 🔄 Notificações por email

---

## 👥 Equipe

**Desenvolvido por:** MSL Estratégia  
**Contato:** contato@mslstrategia.com.br

---

## 📄 Licença

Este projeto é **privado e proprietário**.  
Todos os direitos reservados © 2024 MSL Estratégia.

---

## 🙏 Agradecimentos

- **FastAPI** - Framework web moderna e rápida
- **React** - Biblioteca JavaScript poderosa
- **PostgreSQL** - Banco de dados robusto
- **Docker** - Facilidade de deploy
- **Z-API** - Integração WhatsApp confiável
- **Trello** - API de integração excelente
- Todas as bibliotecas open-source utilizadas

---

## 📞 Suporte

### Para Desenvolvedores

1. Consulte a documentação em `/docs`
2. Verifique os logs: `docker-compose logs -f`
3. Use os scripts de diagnóstico em `scripts/diagnostico/`
4. Abra uma issue no GitHub (se aplicável)

### Para Usuários Finais

Entre em contato com o suporte técnico da MSL Estratégia.

---

## 📖 Recursos Úteis

### Links Importantes

- **Produção Frontend:** http://debrief.interce.com.br
- **Produção Backend:** http://82.25.92.217:2023
- **Documentação API:** http://82.25.92.217:2023/docs

### Comandos Rápidos

```bash
# Ver status geral
docker ps && docker stats --no-stream

# Logs em tempo real
docker-compose -f docker-compose.prod.yml logs -f

# Backup do banco
./scripts/deploy/backup-banco.sh

# Deploy rápido
./EXECUTAR-DEPLOY-SERVIDOR.sh

# Conectar ao banco
./conectar-banco-correto.sh
```

---

**✨ Sistema DeBrief - Gerenciamento Profissional de Demandas**

**🚀 Versão:** 1.1.0  
**📅 Última Atualização:** Novembro 2024  
**💻 Desenvolvido com ❤️ por MSL Estratégia**

---

*Para mais informações, consulte a [documentação completa](docs/README.md).*
