# 📋 Relatório de Memória do Projeto DeBrief
**Data de Atualização:** 23 de Novembro de 2025  
**Status:** Em Desenvolvimento Ativo  
**Ambiente:** Desenvolvimento Local + VPS Produção

---

## 🎯 Visão Geral do Projeto

**Nome:** DeBrief - Sistema de Solicitação de Demandas e Envio de Briefings  
**Objetivo:** Sistema web para gerenciar demandas de clientes com integração automática ao Trello e notificações via WhatsApp

### Stack Tecnológica
- **Frontend:** React 18 + Vite + TailwindCSS + shadcn/ui
- **Backend:** FastAPI (Python 3.11) + SQLAlchemy + Alembic
- **Banco de Dados:** PostgreSQL (produção remota)
- **DevOps:** Docker + Docker Compose + Nginx
- **Integrações:** Trello API + WPPConnect (WhatsApp)

---

## 🔐 Configuração de Acesso SSH Automático

### VPS Hostinger - Informações de Acesso
```bash
# Credenciais SSH
Host: 82.25.92.217
Usuário: root
Porta: 22
Chave SSH: ~/.ssh/id_ed25519
Passphrase: Mslestra2025@
```

### Arquivo de Configuração SSH (~/.ssh/config)
```bash
Host debrief
  HostName 82.25.92.217
  User root
  IdentityFile ~/.ssh/id_ed25519
  # Manter conexão viva
  ServerAliveInterval 60
  ServerAliveCountMax 3
  # Multiplexing (Reutilizar conexão)
  ControlMaster auto
  ControlPath ~/.ssh/cm-%r@%h:%p
  ControlPersist 4h
```

### Como Usar SSH Automático
```bash
# Conexão simples usando alias
ssh debrief

# Executar comando remoto
ssh debrief "docker ps"

# A conexão persiste por 4 horas automaticamente
# Não precisa reautenticar a cada comando
```

---

## 🔌 Túnel SSH para Banco de Dados

### Configuração do Túnel
**Script:** `scripts/dev/tunnel.sh`

```bash
#!/bin/bash
# Mapeia PostgreSQL remoto (servidor:5432) para localhost:5433
SSH_HOST="debrief"
DB_HOST="127.0.0.1"
DB_PORT="5432"
LOCAL_PORT="5433"

ssh -f -N -L $LOCAL_PORT:$DB_HOST:$DB_PORT $SSH_HOST
```

### Credenciais do Banco de Dados
```bash
# Banco Remoto (Produção)
Host: 82.25.92.217
Porta: 5432
Database: dbrief
Usuário: postgres
Senha: Mslestrategia.2025@

# Acesso Local via Túnel
Host: localhost
Porta: 5433
Database: dbrief
Usuário: postgres
Senha: Mslestrategia.2025@

# Connection String (Docker)
DATABASE_URL=postgresql://postgres:Mslestrategia.2025%40@host.docker.internal:5433/dbrief
```

### Como Iniciar o Túnel
```bash
# Iniciar túnel
./scripts/dev/tunnel.sh

# Verificar se está ativo
lsof -iTCP:5433 -sTCP:LISTEN

# Parar túnel
lsof -ti:5433 | xargs kill -9
```

---

## 📁 Estrutura de Diretórios

### Projeto Local (Mac)
```
/Users/alexsantos/Documents/PROJETOS DEV COM IA/DEBRIEF/
├── backend/
│   ├── alembic/
│   │   ├── versions/
│   │   │   ├── fa226c960aba_initial_migration_create_all_tables.py
│   │   │   ├── 001_add_whatsapp_fields_to_users.py ✨ NOVO
│   │   │   ├── 002_create_configuracoes_whatsapp.py ✨ NOVO
│   │   │   ├── 003_create_templates_mensagens.py ✨ NOVO
│   │   │   └── 004_create_notification_logs.py ✨ NOVO
│   │   ├── env.py
│   │   └── alembic.ini
│   ├── app/
│   │   ├── api/
│   │   ├── models/
│   │   ├── services/
│   │   └── core/
│   ├── Dockerfile
│   └── requirements.txt
├── frontend/
│   ├── src/
│   │   ├── components/
│   │   ├── pages/
│   │   │   └── Login.jsx
│   │   └── hooks/
│   ├── Dockerfile
│   └── nginx.conf
├── scripts/
│   └── dev/
│       └── tunnel.sh
├── docs/
│   ├── PROJECT_SPEC.md
│   ├── DESENVOLVIMENTO_LOCAL.md
│   ├── RESUMO_FINAL_DEPLOY.md
│   └── [70+ arquivos de documentação]
├── docker-compose.yml (produção)
├── docker-compose.dev.yml (desenvolvimento)
└── WhatsApp Notifications Setup.md
```

### Projeto no Servidor
```
/var/www/debrief/
├── backend/
├── frontend/
├── docker-compose.yml
└── .env
```

---

## 🐳 Ambiente Docker - Desenvolvimento Local

### Configuração Docker Compose (docker-compose.dev.yml)
```yaml
services:
  backend:
    container_name: debrief-backend
    ports:
      - "8000:8000"
    environment:
      - DATABASE_URL=postgresql://postgres:Mslestrategia.2025%40@host.docker.internal:5433/dbrief
      - FRONTEND_URL=http://localhost:3000
      - ENVIRONMENT=development
    extra_hosts:
      - "host.docker.internal:host-gateway"
    volumes:
      - ./backend:/app
      - ./backend/uploads:/app/uploads

  frontend:
    container_name: debrief-frontend
    ports:
      - "3000:80"
    environment:
      - VITE_API_URL=http://localhost:8000
    volumes:
      - ./frontend:/app
      - /app/node_modules
```

### Comandos Docker
```bash
# Iniciar ambiente de desenvolvimento
docker-compose -f docker-compose.dev.yml up -d

# Ver logs
docker logs debrief-backend --tail 50
docker logs debrief-frontend --tail 50

# Parar ambiente
docker-compose -f docker-compose.dev.yml down

# Rebuild containers
docker-compose -f docker-compose.dev.yml up -d --build

# Executar migrations
docker exec debrief-backend alembic upgrade head

# Acessar container
docker exec -it debrief-backend bash
```

### URLs de Acesso Local
- **Frontend:** http://localhost:3000
- **Backend API:** http://localhost:8000
- **Documentação API:** http://localhost:8000/docs
- **Health Check:** http://localhost:8000/api/health

---

## 📊 Sistema de Notificações WhatsApp - IMPLEMENTADO

### Fase 1: Banco de Dados ✅ COMPLETA

#### Migration 001: Campos WhatsApp em Users
**Arquivo:** `001_add_whatsapp_fields_to_users.py`

**Alterações na tabela `users`:**
```sql
ALTER TABLE users ADD COLUMN whatsapp VARCHAR(20) NULL;
ALTER TABLE users ADD COLUMN receber_notificacoes BOOLEAN NOT NULL DEFAULT true;
CREATE INDEX ix_users_receber_notificacoes ON users(receber_notificacoes);
```

**Campos:**
- `whatsapp`: Número WhatsApp no formato 5511999999999
- `receber_notificacoes`: Flag para ativar/desativar notificações

#### Migration 002: Tabela de Configurações WhatsApp
**Arquivo:** `002_create_configuracoes_whatsapp.py`

**Nova tabela `configuracoes_whatsapp`:**
```sql
CREATE TABLE configuracoes_whatsapp (
    id VARCHAR(36) PRIMARY KEY,
    numero_remetente VARCHAR(20) NOT NULL,
    instancia_wpp VARCHAR(100) NOT NULL,
    ativo BOOLEAN NOT NULL DEFAULT true,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT now(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT now()
);
```

**Propósito:** Armazenar configurações do número WhatsApp Business remetente e instância WPPConnect

#### Migration 003: Templates de Mensagens
**Arquivo:** `003_create_templates_mensagens.py`

**Nova tabela `templates_mensagens`:**
```sql
CREATE TABLE templates_mensagens (
    id VARCHAR(36) PRIMARY KEY,
    nome VARCHAR(100) NOT NULL UNIQUE,
    tipo_evento VARCHAR(50) NOT NULL,
    mensagem TEXT NOT NULL,
    variaveis_disponiveis TEXT,
    ativo BOOLEAN NOT NULL DEFAULT true,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT now(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT now()
);
```

**Tipos de Eventos:**
- `demanda_criada`
- `demanda_atualizada`
- `demanda_concluida`
- `demanda_cancelada`

**Variáveis Disponíveis:**
- `{demanda_titulo}`
- `{demanda_descricao}`
- `{cliente_nome}`
- `{secretaria_nome}`
- `{tipo_demanda}`
- `{prioridade}`
- `{prazo_final}`
- `{usuario_responsavel}`
- `{usuario_nome}`
- `{data_criacao}`
- `{trello_card_url}`

#### Migration 004: Logs de Notificações
**Arquivo:** `004_create_notification_logs.py`

**Nova tabela `notification_logs`:**
```sql
CREATE TABLE notification_logs (
    id VARCHAR(36) PRIMARY KEY,
    demanda_id VARCHAR(36),
    usuario_id VARCHAR(36),
    tipo VARCHAR(50) NOT NULL,
    destinatario VARCHAR(100) NOT NULL,
    mensagem TEXT NOT NULL,
    status VARCHAR(20) NOT NULL DEFAULT 'pendente',
    erro_mensagem TEXT,
    metadata JSONB,
    enviado_em TIMESTAMP WITH TIME ZONE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT now(),
    FOREIGN KEY (demanda_id) REFERENCES demandas(id) ON DELETE SET NULL,
    FOREIGN KEY (usuario_id) REFERENCES users(id) ON DELETE SET NULL
);
```

**Status Possíveis:**
- `pendente`: Aguardando envio
- `enviado`: Notificação enviada com sucesso
- `erro`: Falha no envio
- `cancelado`: Notificação cancelada

### Próximas Fases - PENDENTES

#### Fase 2: Backend (Endpoints e Serviços)
**Estimativa:** 4-6 horas

**Tarefas:**
1. ✅ Criar modelos SQLAlchemy para novas tabelas
2. ⏳ Criar endpoints REST:
   - `POST /api/configuracoes/whatsapp` - Configurar número remetente
   - `GET /api/configuracoes/whatsapp` - Obter configurações
   - `PUT /api/configuracoes/whatsapp/{id}` - Atualizar configurações
   - `POST /api/templates-mensagens` - Criar template
   - `GET /api/templates-mensagens` - Listar templates
   - `PUT /api/templates-mensagens/{id}` - Editar template
   - `GET /api/notification-logs` - Histórico de notificações
3. ⏳ Criar serviço WhatsApp (`services/whatsapp_service.py`)
4. ⏳ Integrar com WPPConnect
5. ⏳ Implementar renderização de templates
6. ⏳ Hooks em criar/editar/deletar demandas

#### Fase 3: Frontend (Interfaces)
**Estimativa:** 5-7 horas

**Páginas a criar:**
1. ⏳ Configurações WhatsApp (`/admin/configuracoes/whatsapp`)
   - Formulário para número remetente
   - Campo instância WPPConnect
   - Botão testar conexão
2. ⏳ Gerenciar Templates (`/admin/templates-mensagens`)
   - Lista de templates
   - Editor de templates com preview
   - Seletor de variáveis dinâmicas
3. ⏳ Histórico de Notificações (`/admin/notificacoes`)
   - Tabela de logs
   - Filtros (status, data, destinatário)
   - Detalhes de erros
4. ⏳ Adicionar campo WhatsApp no cadastro de usuários

#### Fase 4: Testes e Integração
**Estimativa:** 2-4 horas

**Checklist:**
- ⏳ Testar envio de notificação individual
- ⏳ Validar renderização de templates
- ⏳ Testar todos os tipos de eventos
- ⏳ Verificar tratamento de erros
- ⏳ Testar com WPPConnect real

---

## 🔄 Fluxo de Trabalho Recomendado

### 1. Desenvolvimento Local com Banco Remoto (ATUAL)
```bash
# Passo 1: Iniciar túnel SSH
./scripts/dev/tunnel.sh

# Passo 2: Verificar túnel
lsof -iTCP:5433 -sTCP:LISTEN

# Passo 3: Iniciar containers Docker
docker-compose -f docker-compose.dev.yml up -d

# Passo 4: Verificar logs
docker logs debrief-backend
docker logs debrief-frontend

# Passo 5: Acessar aplicação
# Frontend: http://localhost:3000
# Backend: http://localhost:8000/docs
```

### 2. Aplicar Migrations
```bash
# Via Docker
docker exec debrief-backend alembic upgrade head

# Verificar versão atual
docker exec debrief-backend alembic current

# Ver histórico
docker exec debrief-backend alembic history
```

### 3. Deploy no Servidor
```bash
# Conectar ao servidor (usa configuração ~/.ssh/config)
ssh debrief

# Navegar para projeto
cd /var/www/debrief

# Atualizar código
git pull origin main

# Rebuild e restart
docker-compose down
docker-compose up -d --build

# Aplicar migrations
docker-compose exec backend alembic upgrade head

# Verificar status
docker-compose ps
docker-compose logs -f
```

---

## 📚 Documentação Disponível

### Documentos Principais
1. **PROJECT_SPEC.md** - Especificação completa do sistema
2. **DESENVOLVIMENTO_LOCAL.md** - Guia de desenvolvimento local
3. **RESUMO_FINAL_DEPLOY.md** - Guia de deploy em produção
4. **WhatsApp Notifications Setup.md** - Histórico de implementação WhatsApp

### Documentação por Área
- **Backend:** `/docs/backend/`
- **Frontend:** `/docs/frontend/`
- **Modelos:** `/docs/backend/app/models/`
- **Componentes:** `/docs/frontend/src/components/`

### Total de Documentos
- **79 arquivos** `.md` na pasta `docs/`
- Cobertura completa de todas as funcionalidades
- Guias de troubleshooting
- Exemplos de código

---

## 🔒 Segurança e Credenciais

### Variáveis de Ambiente (.env)
```bash
# Database
DATABASE_URL=postgresql://postgres:Mslestrategia.2025@82.25.92.217:5432/dbrief

# JWT
SECRET_KEY=sua-chave-secreta-super-segura-aqui-change-me
ALGORITHM=HS256
ACCESS_TOKEN_EXPIRE_MINUTES=30

# Frontend
FRONTEND_URL=http://localhost:3000

# WPPConnect (Quando configurado)
WPP_URL=http://localhost:21465
WPP_INSTANCE=debrief-instance
WPP_TOKEN=<token-wppconnect>

# Trello (Quando configurado)
TRELLO_API_KEY=<api-key>
TRELLO_TOKEN=<token>
TRELLO_BOARD_ID=<board-id>
TRELLO_LIST_ID=<list-id>
```

### ⚠️ Avisos de Segurança
1. **Nunca commitar arquivos `.env`**
2. **Trocar senhas padrão em produção**
3. **Usar HTTPS em produção**
4. **Configurar firewall no servidor**
5. **Backup regular do banco de dados**

---

## 🐛 Troubleshooting Comum

### Problema: Login não funciona
**Solução:**
```bash
# Verificar backend
curl http://localhost:8000/api/health

# Verificar logs
docker logs debrief-backend --tail 50

# Credenciais padrão
username: admin
password: admin123
```

### Problema: Túnel SSH não conecta
**Solução:**
```bash
# Verificar conexão SSH
ssh debrief "echo 'Conexão OK'"

# Verificar se porta está em uso
lsof -i :5433

# Matar processo antigo
lsof -ti:5433 | xargs kill -9

# Reiniciar túnel
./scripts/dev/tunnel.sh
```

### Problema: Migrations não aplicam
**Solução:**
```bash
# Verificar conexão com banco
docker exec debrief-backend psql $DATABASE_URL -c "SELECT 1"

# Ver migrations pendentes
docker exec debrief-backend alembic current
docker exec debrief-backend alembic heads

# Forçar upgrade
docker exec debrief-backend alembic upgrade head
```

### Problema: Container não inicia
**Solução:**
```bash
# Ver logs detalhados
docker logs debrief-backend --tail 100

# Rebuild completo
docker-compose -f docker-compose.dev.yml down
docker-compose -f docker-compose.dev.yml up -d --build --force-recreate

# Verificar portas em uso
lsof -i :8000
lsof -i :3000
```

---

## 📈 Status do Projeto

### Funcionalidades Implementadas ✅
- [x] Sistema de autenticação JWT
- [x] CRUD de Usuários
- [x] CRUD de Clientes
- [x] CRUD de Secretarias
- [x] CRUD de Tipos de Demanda
- [x] CRUD de Prioridades
- [x] CRUD de Demandas
- [x] Upload de anexos
- [x] Dashboard com métricas
- [x] Relatórios com filtros
- [x] Integração Trello (preparado)
- [x] Sistema de notificações WhatsApp (Fase 1: Banco de Dados)

### Em Desenvolvimento 🚧
- [ ] Sistema de notificações WhatsApp (Fase 2: Backend)
- [ ] Sistema de notificações WhatsApp (Fase 3: Frontend)
- [ ] Sistema de notificações WhatsApp (Fase 4: Testes)

### Planejado 📋
- [ ] Configuração completa Trello
- [ ] Exportação de relatórios (PDF/Excel)
- [ ] Integração completa WPPConnect
- [ ] Notificações em tempo real
- [ ] Configurar SSL/HTTPS
- [ ] Backup automático

---

## 🎯 Próximas Ações Recomendadas

### Curto Prazo (Hoje/Amanhã)
1. ✅ Finalizar documentação e relatório de memória
2. ⏳ Implementar Fase 2: Backend do sistema WhatsApp
3. ⏳ Criar endpoints de configuração
4. ⏳ Implementar serviço de envio de mensagens

### Médio Prazo (Esta Semana)
1. ⏳ Implementar Fase 3: Frontend do sistema WhatsApp
2. ⏳ Criar interfaces de configuração
3. ⏳ Testar envio de notificações
4. ⏳ Documentar APIs criadas

### Longo Prazo (Este Mês)
1. ⏳ Configurar WPPConnect em produção
2. ⏳ Integrar Trello completamente
3. ⏳ Implementar exportação de relatórios
4. ⏳ Configurar SSL no servidor

---

## 📞 Comandos Rápidos de Referência

### SSH e Servidor
```bash
# Conectar ao servidor
ssh debrief

# Executar comando remoto
ssh debrief "docker ps"

# Copiar arquivo para servidor
scp arquivo.txt debrief:/var/www/debrief/

# Copiar arquivo do servidor
scp debrief:/var/www/debrief/arquivo.txt ./
```

### Docker Local
```bash
# Iniciar
docker-compose -f docker-compose.dev.yml up -d

# Parar
docker-compose -f docker-compose.dev.yml down

# Logs
docker logs debrief-backend -f

# Shell
docker exec -it debrief-backend bash
```

### Database
```bash
# Conectar via túnel local
psql postgresql://postgres:Mslestrategia.2025@localhost:5433/dbrief

# Via Docker
docker exec debrief-backend psql $DATABASE_URL -c "SELECT * FROM users;"
```

### Git
```bash
# Atualizar código local
git pull origin main

# Ver mudanças
git status
git diff

# Commit
git add .
git commit -m "descrição"
git push origin main
```

---

## 📝 Notas Importantes

### Sobre o Banco de Dados
- ⚠️ **Ambiente de desenvolvimento conecta ao banco de PRODUÇÃO**
- Todas as alterações afetam dados reais
- Usar com cuidado ao testar
- Fazer backup antes de mudanças grandes

### Sobre SSH Persistente
- Configuração ControlMaster mantém conexão por 4 horas
- Não precisa reautenticar a cada comando
- Conexão é reutilizada automaticamente
- Para forçar nova conexão: `ssh -O exit debrief`

### Sobre Migrations
- Sempre testar migrations localmente primeiro
- Fazer backup do banco antes de aplicar em produção
- Migrations são versionadas e rastreáveis
- Rollback disponível via `alembic downgrade`

---

## 🎊 Conclusão

Este projeto está bem estruturado com:
- ✅ Acesso SSH automático configurado
- ✅ Túnel SSH para banco de dados funcionando
- ✅ Ambiente de desenvolvimento local operacional
- ✅ Sistema de migrations organizado
- ✅ Documentação completa e atualizada
- ✅ Fase 1 do sistema WhatsApp implementada

**Status:** Pronto para continuar implementação das Fases 2, 3 e 4 do sistema de notificações WhatsApp.

---

**Última Atualização:** 23 de Novembro de 2025  
**Responsável:** Cursor AI + Alex Santos  
**Versão do Relatório:** 1.0


