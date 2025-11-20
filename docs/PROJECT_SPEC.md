# 🎯 DeBrief - Sistema de Solicitação de Demandas e Envio de Briefings

## 📋 VISÃO GERAL DO PROJETO

**Nome:** DeBrief  
**Objetivo:** Sistema web para gerenciar demandas de clientes com integração automática ao Trello e notificações via WhatsApp  
**Stack:** React (Frontend) + FastAPI (Backend) + PostgreSQL (Database)

---

## 🎨 RESUMO EXECUTIVO

O DeBrief é um sistema que automatiza o fluxo de solicitações de demandas:
1. Cliente preenche formulário web bonito e intuitivo (React)
2. Sistema cria card automaticamente no Trello
3. Notificação é enviada ao grupo de WhatsApp do cliente
4. Cliente pode acompanhar e editar suas demandas
5. Sistema gera relatórios detalhados com gráficos interativos

**Analogia:** É como um assistente pessoal que recebe pedidos, organiza numa agenda (Trello) e avisa todo mundo por WhatsApp - tudo automaticamente!

---

## 🏗️ ARQUITETURA DO SISTEMA

```
┌─────────────────────────────────────────────────────┐
│  FRONTEND (React + Vite)                            │
│  - Interface moderna e responsiva                    │
│  - Formulários validados                             │
│  - Dashboards com gráficos interativos              │
│  - Porta: 5173 (dev) / 80,443 (prod)               │
└─────────────┬───────────────────────────────────────┘
              │ API REST (HTTPS)
              ▼
┌─────────────────────────────────────────────────────┐
│  BACKEND (FastAPI + Python)                         │
│  - API RESTful                                       │
│  - Autenticação JWT                                  │
│  - Integração Trello API                            │
│  - Integração WPPConnect                            │
│  - Geração de relatórios PDF/Excel                  │
│  - Porta: 8000                                       │
└─────────────┬───────────────────────────────────────┘
              │
              ▼
┌─────────────────────────────────────────────────────┐
│  DATABASE (PostgreSQL)                              │
│  - Armazenamento persistente                        │
│  - Relacionamentos entre entidades                  │
│  - Porta: 5432                                       │
└─────────────────────────────────────────────────────┘

INTEGRAÇÕES EXTERNAS:
├── Trello API (criar/editar cards)
├── WPPConnect (enviar mensagens WhatsApp)
└── Uploadcare/Storage (armazenar anexos)
```

---

## 📊 MODELO DE DADOS (Entidades do Sistema)

### 1. **USUÁRIOS** (users)
```
- id: UUID (chave primária)
- username: string (único)
- email: string (único)
- password_hash: string (senha criptografada)
- nome_completo: string
- tipo: enum ['master', 'cliente'] (master = admin)
- cliente_id: UUID (FK para clientes) - NULL se for master
- ativo: boolean (desativar sem deletar)
- created_at: timestamp
- updated_at: timestamp
```

### 2. **CLIENTES** (clientes)
```
- id: UUID (chave primária)
- nome: string (nome da empresa/órgão)
- whatsapp_group_id: string (ID do grupo WhatsApp)
- trello_member_id: string (ID do membro no Trello)
- ativo: boolean
- created_at: timestamp
- updated_at: timestamp
```

### 3. **SECRETARIAS** (secretarias)
```
- id: UUID (chave primária)
- nome: string
- cliente_id: UUID (FK para clientes)
- ativo: boolean
- created_at: timestamp
- updated_at: timestamp
```

### 4. **TIPOS DE DEMANDA** (tipos_demanda)
```
- id: UUID (chave primária)
- nome: string (ex: "Design", "Desenvolvimento", "Conteúdo")
- cor: string (hex color para UI - ex: "#FF5733")
- ativo: boolean
- created_at: timestamp
```

### 5. **PRIORIDADES** (prioridades)
```
- id: UUID (chave primária)
- nome: string (ex: "Baixa", "Média", "Alta", "Urgente")
- nivel: integer (1-4, para ordenação)
- cor: string (hex color)
- created_at: timestamp
```

### 6. **DEMANDAS** (demandas)
```
- id: UUID (chave primária)
- nome: string (título da demanda)
- descricao: text (descrição detalhada)
- secretaria_id: UUID (FK para secretarias)
- tipo_demanda_id: UUID (FK para tipos_demanda)
- prioridade_id: UUID (FK para prioridades)
- prazo_final: date
- usuario_id: UUID (FK para users - quem criou)
- cliente_id: UUID (FK para clientes)
- trello_card_id: string (ID do card no Trello)
- trello_card_url: string (URL do card)
- status: enum ['aberta', 'em_andamento', 'concluida', 'cancelada']
- created_at: timestamp
- updated_at: timestamp
```

### 7. **ANEXOS** (anexos)
```
- id: UUID (chave primária)
- demanda_id: UUID (FK para demandas)
- nome_arquivo: string
- caminho: string (path no servidor ou URL)
- tamanho: integer (bytes)
- tipo_mime: string
- trello_attachment_id: string (ID do anexo no Trello)
- created_at: timestamp
```

### 8. **CONFIGURAÇÕES** (configuracoes)
```
- id: UUID (chave primária)
- chave: string (ex: "trello_api_key", "wpp_instance_id")
- valor: text (valor criptografado)
- descricao: string
- updated_at: timestamp
```

### 9. **LOGS DE NOTIFICAÇÕES** (notification_logs)
```
- id: UUID (chave primária)
- demanda_id: UUID (FK para demandas)
- tipo: enum ['whatsapp', 'trello']
- status: enum ['enviado', 'erro', 'pendente']
- mensagem_erro: text (se houver erro)
- created_at: timestamp
```

---

## 🎨 FUNCIONALIDADES DETALHADAS

### 👤 ÁREA DE USUÁRIOS NORMAIS (Clientes)

#### 1. **Dashboard Principal**
- Card com total de demandas (abertas, em andamento, concluídas)
- Gráfico de evolução mensal
- Últimas 5 demandas criadas
- Atalho para nova demanda

#### 2. **Formulário de Nova Demanda**
Campos:
- **Secretaria:** Dropdown (carrega secretarias do cliente logado)
- **Nome da Demanda:** Input text (máx 200 caracteres)
- **Tipo de Demanda:** Dropdown (ex: Design, Vídeo, Post)
- **Prioridade:** Dropdown com cores (Baixa🟢, Média🟡, Alta🟠, Urgente🔴)
- **Descrição:** Textarea (editor rico opcional)
- **Prazo Final:** Date picker (não pode ser data passada)
- **Anexos:** Upload múltiplo (máx 50MB, aceita PDF e imagens)

**Validações:**
- Todos os campos obrigatórios exceto anexos
- Prazo deve ser data futura
- Limite de 5 anexos por demanda

**Ações ao enviar:**
1. Salvar no banco PostgreSQL
2. Criar card no Trello (lista "ENVIOS DOS CLIENTES VIA DEBRIEF")
3. Título do card: "[Nome da Demanda] - [Nome do Cliente]"
4. Anexar arquivos no card do Trello
5. Enviar notificação WhatsApp no grupo do cliente
6. Mostrar mensagem de sucesso com link do card

#### 3. **Minhas Demandas**
- Tabela paginada com filtros:
  - Busca por nome
  - Filtro por tipo de demanda
  - Filtro por status
  - Filtro por período (data de criação)
  
- Colunas da tabela:
  - Nome da demanda
  - Tipo
  - Prioridade (com badge colorido)
  - Status (badge)
  - Prazo final (destaque se próximo/vencido)
  - Ações: [Editar] [Ver no Trello] [Detalhes]

- **Editar Demanda:**
  - Abre modal com formulário preenchido
  - Ao salvar: atualiza banco + atualiza card no Trello
  - Não pode editar: tipo, secretaria (somente admin)
  - Pode adicionar novos anexos

#### 4. **Relatórios do Usuário**
Filtros:
- Tipo de demanda (múltipla escolha)
- Secretaria (múltipla escolha)
- Período (data inicial e final)
- Status

Visualizações:
- **Tabela resumida:**
  - Total por tipo de demanda
  - Total por secretaria
  - Total por status
  - Média de dias até conclusão
  
- **Gráficos:**
  - Gráfico de pizza: Distribuição por tipo
  - Gráfico de barras: Evolução mensal
  - Gráfico de linhas: Tendência de abertura de demandas

- **Exportação:**
  - Botão "Exportar PDF" (relatório formatado)
  - Botão "Exportar Excel" (dados tabulares)

---

### 👑 ÁREA MASTER (Administradores)

Acesso adicional às seguintes funcionalidades:

#### 1. **Gerenciar Usuários**
- Listagem de todos os usuários
- Criar novo usuário:
  - Username, email, senha
  - Tipo (master ou cliente)
  - Se cliente: vincular a um cliente existente
  - Status ativo/inativo
  
- Editar usuário:
  - Alterar dados cadastrais
  - Resetar senha
  - Ativar/desativar
  
- Não pode deletar (somente desativar)

#### 2. **Gerenciar Clientes**
- Listagem de clientes
- Criar cliente:
  - Nome da empresa/órgão
  - ID do grupo WhatsApp (instrução de como obter)
  - ID do membro Trello (instrução de como obter)
  
- Editar cliente:
  - Atualizar informações
  - Ativar/desativar
  
- Ao desativar: usuários vinculados não podem mais logar
- Ver estatísticas do cliente (total de demandas, etc)

#### 3. **Gerenciar Secretarias**
- Listagem por cliente
- Criar secretaria:
  - Nome
  - Cliente vinculado
  
- Editar/Desativar secretaria
- Validação: não permitir deletar se houver demandas vinculadas

#### 4. **Gerenciar Tipos de Demanda**
- Listagem
- Criar tipo:
  - Nome
  - Cor (color picker)
  
- Editar/Desativar
- Tipos inativos não aparecem no formulário

#### 5. **Gerenciar Prioridades**
- Listagem
- Criar prioridade:
  - Nome
  - Nível (1-4)
  - Cor
  
- Editar/Desativar
- Ordenação por nível

#### 6. **Configurações do Sistema**
Interface para gerenciar:

**Trello:**
- API Key (input com máscara)
- Token (input com máscara)
- Board ID (input)
- List ID da lista "ENVIOS DOS CLIENTES VIA DEBRIEF"
- Botão "Testar Conexão"

**WPPConnect:**
- URL da instância (ex: http://localhost:21465)
- Instance name
- Token de autenticação
- Botão "Testar Conexão" (envia mensagem teste)

**Sistema:**
- Tamanho máximo de upload (em MB)
- Formatos permitidos
- Tempo de sessão (minutos)

#### 7. **Relatórios Master (Completos)**
Filtros adicionais:
- Cliente (múltipla escolha)
- Usuário que criou
- Todos os filtros dos usuários normais

Visualizações adicionais:
- Ranking de clientes por volume de demandas
- Performance por tipo de demanda
- Taxa de conclusão por cliente
- Gráfico de funil (status das demandas)
- Comparativo mensal year-over-year

Exportações:
- Relatório executivo em PDF
- Planilha detalhada em Excel

---

## 🔐 SISTEMA DE AUTENTICAÇÃO

### Fluxo de Login:
1. Usuário acessa `/login`
2. Digita username e senha
3. Frontend faz POST para `/api/auth/login`
4. Backend valida credenciais
5. Backend gera JWT token (validade: 8 horas)
6. Token retorna para frontend
7. Frontend armazena em localStorage
8. Frontend redireciona baseado em tipo:
   - Master → `/admin/dashboard`
   - Cliente → `/dashboard`

### Proteção de Rotas:
- Frontend: React Router com PrivateRoute component
- Backend: Dependency Injection do FastAPI com `get_current_user`
- Middleware verifica JWT em todas as rotas protegidas

### Logout:
- Clear do localStorage
- Redirect para `/login`
- Backend invalida token (blacklist opcional)

### Captcha:
- Google reCAPTCHA v3 no formulário de login
- Validação no backend antes de verificar credenciais

---

## 🔗 INTEGRAÇÕES DETALHADAS

### 1. **TRELLO API**

**Biblioteca:** `py-trello`

**Configuração:**
```python
# Necessário obter:
# - API Key: https://trello.com/app-key
# - Token: gerar na mesma página acima
# - Board ID: extrair da URL do board
# - List ID: via API ou URL da lista
```

**Operações:**

**Criar Card:**
```python
# Quando usuário criar demanda
card = trello_list.add_card(
    name=f"{demanda.nome} - {cliente.nome}",
    desc=f"""
    **Secretaria:** {secretaria.nome}
    **Tipo:** {tipo_demanda.nome}
    **Prioridade:** {prioridade.nome}
    **Prazo:** {demanda.prazo_final}
    
    **Descrição:**
    {demanda.descricao}
    
    **Solicitante:** {usuario.nome_completo}
    """,
    position='top'
)

# Adicionar labels (usar cores das prioridades)
card.add_label(prioridade.nome, prioridade.cor)

# Adicionar member (cliente)
card.add_member(cliente.trello_member_id)

# Adicionar anexos
for anexo in demanda.anexos:
    card.attach(url=anexo.url)

# Salvar IDs no banco
demanda.trello_card_id = card.id
demanda.trello_card_url = card.url
```

**Atualizar Card:**
```python
# Quando usuário editar demanda
card = board.get_card(demanda.trello_card_id)
card.set_name(f"{demanda.nome} - {cliente.nome}")
card.set_description(nova_descricao)
card.set_due(demanda.prazo_final)
```

**Tratamento de Erros:**
- Tentar 3 vezes antes de falhar
- Se falhar: salvar no banco mesmo assim
- Criar fila de retry (processar depois)
- Log de erros na tabela notification_logs

---

### 2. **WPPCONNECT**

**Biblioteca:** Requests (HTTP API)

**Setup WPPConnect:**
```bash
# Instalar WPPConnect Server
npm install -g @wppconnect-team/wppconnect-server

# Iniciar servidor
wppconnect-server

# Acessar: http://localhost:21465
# Escanear QR Code com WhatsApp
```

**Configuração no sistema:**
- Armazenar: URL, instance name, token
- Testar conexão na página de configurações

**Enviar Mensagem:**
```python
import requests

def enviar_notificacao_whatsapp(demanda, cliente):
    url = f"{wpp_url}/api/{instance_name}/send-text"
    
    mensagem = f"""
🔔 *Nova Demanda Recebida!*

📋 *Demanda:* {demanda.nome}
🏢 *Secretaria:* {secretaria.nome}
📌 *Tipo:* {tipo_demanda.nome}
⚡ *Prioridade:* {prioridade.nome}
📅 *Prazo:* {demanda.prazo_final.strftime('%d/%m/%Y')}

👤 *Solicitante:* {usuario.nome_completo}

🔗 Ver no Trello: {demanda.trello_card_url}
    """
    
    payload = {
        "phone": cliente.whatsapp_group_id,  # ID do grupo
        "message": mensagem,
        "isGroup": True
    }
    
    headers = {
        "Authorization": f"Bearer {wpp_token}",
        "Content-Type": "application/json"
    }
    
    response = requests.post(url, json=payload, headers=headers)
    return response.json()
```

**Quando Enviar:**
1. Nova demanda criada ✅
2. Demanda editada pelo usuário ✅
3. Status alterado para "concluída" (opcional)

**Tratamento de Erros:**
- Retry automático (3 tentativas)
- Log de falhas
- Não bloquear criação de demanda se WhatsApp falhar

---

## 📱 DESIGN E UI/UX

### Paleta de Cores Sugerida:
```css
/* Cores Primárias */
--primary: #3B82F6 (azul vibrante)
--secondary: #8B5CF6 (roxo)
--accent: #10B981 (verde sucesso)

/* Cores de Status */
--success: #10B981
--warning: #F59E0B
--error: #EF4444
--info: #3B82F6

/* Prioridades */
--priority-low: #10B981 (verde)
--priority-medium: #F59E0B (amarelo)
--priority-high: #F97316 (laranja)
--priority-urgent: #EF4444 (vermelho)

/* Neutros */
--gray-50: #F9FAFB
--gray-100: #F3F4F6
--gray-800: #1F2937
--gray-900: #111827
```

### Componentes UI (usar shadcn/ui):
- Button (vários estilos)
- Input, Textarea
- Select (dropdown bonito)
- DatePicker (calendário)
- Table (paginação, ordenação)
- Modal/Dialog
- Alert/Toast (notificações)
- Card
- Badge
- Tabs
- Skeleton (loading state)

### Responsividade:
- Mobile-first approach
- Breakpoints: 640px (sm), 768px (md), 1024px (lg), 1280px (xl)
- Menu hamburguer em mobile
- Tabelas scrolláveis em mobile

### Animações:
- Transições suaves (Framer Motion)
- Loading states
- Skeleton screens
- Page transitions

---

## 📦 UPLOAD DE ARQUIVOS

### Estratégia:
1. Frontend: validação de tamanho e tipo
2. Backend: validação adicional
3. Armazenamento: pasta `/uploads` no servidor
4. Estrutura: `/uploads/{cliente_id}/{demanda_id}/`
5. Nome do arquivo: UUID + extensão original
6. Upload para Trello: usar URL pública ou base64

### Validações:
- Tamanho máximo: 50MB por arquivo
- Tipos permitidos: .pdf, .jpg, .jpeg, .png
- Máximo 5 arquivos por demanda
- Scan de vírus (opcional: ClamAV)

### Segurança:
- Não servir arquivos diretamente
- Endpoint protegido para download
- Verificar permissão antes de servir
- Sanitizar nome de arquivo

---

## 📊 GERAÇÃO DE RELATÓRIOS

### PDF (usar ReportLab):
```python
from reportlab.lib.pagesizes import A4
from reportlab.platypus import SimpleDocTemplate, Table, Paragraph
from reportlab.lib.styles import getSampleStyleSheet

# Template profissional
# Header com logo
# Filtros aplicados
# Tabelas formatadas
# Gráficos (converter charts para imagem)
# Footer com data de geração
```

### Excel (usar openpyxl):
```python
from openpyxl import Workbook
from openpyxl.styles import Font, PatternFill

# Múltiplas abas:
# - Resumo
# - Dados detalhados
# - Gráficos
# Formatação: cores, bordas, autofit
```

---

## 🚀 ETAPAS DE DESENVOLVIMENTO

### FASE 1: Setup do Projeto ✅
- Criar estrutura de pastas
- Configurar ambiente virtual Python
- Instalar dependências frontend/backend
- Configurar Git (.gitignore)

### FASE 2: Frontend Base 🎨
1. Setup Vite + React
2. Configurar TailwindCSS + shadcn/ui
3. Criar componentes base (Button, Input, Card)
4. Implementar sistema de rotas
5. Criar layout base (Header, Sidebar, Footer)
6. Tela de login (sem funcionalidade)
7. Dashboard skeleton

### FASE 3: Backend Base 🐍
1. Setup FastAPI
2. Configurar PostgreSQL + SQLAlchemy
3. Criar modelos (todas as tabelas)
4. Implementar autenticação JWT
5. Criar endpoints básicos de auth
6. Migrations com Alembic
7. Seeds iniciais (usuário master)

### FASE 4: Integração Auth 🔐
1. Conectar frontend com backend (login)
2. Armazenar token
3. Proteger rotas frontend
4. Middleware backend
5. Implementar logout
6. Adicionar reCAPTCHA

### FASE 5: CRUD Demandas ✍️
1. Formulário de nova demanda (frontend)
2. Endpoint criar demanda (backend)
3. Validações completas
4. Upload de arquivos
5. Listagem de demandas
6. Filtros e busca
7. Edição de demanda
8. Modal de detalhes

### FASE 6: Integrações 🔗
1. Integrar Trello API
2. Criar card ao criar demanda
3. Atualizar card ao editar
4. Adicionar anexos no Trello
5. Configurar WPPConnect
6. Enviar notificação ao criar demanda
7. Logs de integrações

### FASE 7: Área Admin 👑
1. CRUD Usuários
2. CRUD Clientes
3. CRUD Secretarias
4. CRUD Tipos de Demanda
5. CRUD Prioridades
6. Página de configurações
7. Testar conexões (Trello/WhatsApp)

### FASE 8: Relatórios 📈
1. Filtros dinâmicos
2. Queries otimizadas
3. Gráficos com Recharts
4. Geração de PDF
5. Geração de Excel
6. Dashboard com métricas

### FASE 9: Polimento 💎
1. Melhorias de UI/UX
2. Loading states
3. Tratamento de erros
4. Mensagens de feedback
5. Validações visuais
6. Testes manuais
7. Otimizações de performance

### FASE 10: Deploy 🚀
1. Configurar Nginx
2. SSL (Let's Encrypt)
3. PM2 para backend
4. Build do frontend
5. Variáveis de ambiente
6. Backup do banco
7. Monitoramento

---

## 🔧 TECNOLOGIAS E DEPENDÊNCIAS

### Frontend (package.json):
```json
{
  "dependencies": {
    "react": "^18.3.1",
    "react-dom": "^18.3.1",
    "react-router-dom": "^6.22.0",
    "axios": "^1.6.7",
    "@tanstack/react-query": "^5.28.0",
    "react-hook-form": "^7.51.0",
    "zod": "^3.22.4",
    "@hookform/resolvers": "^3.3.4",
    "recharts": "^2.12.2",
    "date-fns": "^3.3.1",
    "lucide-react": "^0.344.0",
    "clsx": "^2.1.0",
    "tailwind-merge": "^2.2.1",
    "react-google-recaptcha": "^3.1.0"
  },
  "devDependencies": {
    "@vitejs/plugin-react": "^4.2.1",
    "vite": "^5.1.4",
    "tailwindcss": "^3.4.1",
    "autoprefixer": "^10.4.18",
    "postcss": "^8.4.35"
  }
}
```

### Backend (requirements.txt):
```
fastapi==0.110.0
uvicorn[standard]==0.27.1
sqlalchemy==2.0.27
psycopg2-binary==2.9.9
alembic==1.13.1
python-jose[cryptography]==3.3.0
passlib[bcrypt]==1.7.4
python-multipart==0.0.9
py-trello==0.19.0
requests==2.31.0
python-dotenv==1.0.1
reportlab==4.1.0
openpyxl==3.1.2
pillow==10.2.0
aiofiles==23.2.1
pydantic[email]==2.6.3
```

---

## 🔒 SEGURANÇA

### Práticas Implementadas:
1. **Senhas:** Hash com bcrypt (salt automático)
2. **JWT:** Assinado com HS256, expiração 8h
3. **CORS:** Configurado para domínio específico
4. **SQL Injection:** Prevenido por ORM
5. **XSS:** Sanitização de inputs
6. **CSRF:** Token em formulários críticos
7. **Rate Limiting:** 100 requests/minuto por IP
8. **File Upload:** Validação rigorosa de tipo/tamanho
9. **Environment Variables:** Senhas em .env (nunca no código)
10. **HTTPS:** Obrigatório em produção

### Variáveis Sensíveis (.env):
```
# Database
DATABASE_URL=postgresql://user:pass@localhost:5432/debrief

# JWT
SECRET_KEY=sua-chave-super-secreta-aqui-min-32-chars
ALGORITHM=HS256
ACCESS_TOKEN_EXPIRE_MINUTES=480

# Trello
TRELLO_API_KEY=sua-api-key
TRELLO_TOKEN=seu-token
TRELLO_BOARD_ID=id-do-board
TRELLO_LIST_ID=id-da-lista

# WPPConnect
WPP_URL=http://localhost:21465
WPP_INSTANCE=debrief-instance
WPP_TOKEN=seu-token-wpp

# reCAPTCHA
RECAPTCHA_SECRET_KEY=sua-chave-secreta

# Upload
UPLOAD_DIR=/home/usuario/debrief/backend/uploads
MAX_UPLOAD_SIZE=52428800  # 50MB em bytes
```

---

## 📖 CONVENÇÕES DE CÓDIGO

### Python (Backend):
- PEP 8 compliance
- Type hints em todas as funções
- Docstrings em funções públicas
- Nomes em snake_case
- Classes em PascalCase
- Comentários em português explicando lógica complexa

### JavaScript (Frontend):
- ES6+ features
- Componentes funcionais (Hooks)
- PascalCase para componentes
- camelCase para funções/variáveis
- Comentários em português
- Destructuring quando possível
- Arrow functions

### Git:
- Commits em português
- Formato: `tipo: descrição`
- Tipos: feat, fix, refactor, docs, style, test
- Exemplo: `feat: adiciona formulário de demanda`

---

## 🐛 TRATAMENTO DE ERROS

### Frontend:
```javascript
// Usar React Query para gerenciar estados
const { data, isLoading, error } = useQuery({
  queryKey: ['demandas'],
  queryFn: fetchDemandas,
  retry: 3,
  onError: (error) => {
    toast.error('Erro ao carregar demandas')
  }
})

// Try-catch em operações críticas
try {
  await criarDemanda(dados)
  toast.success('Demanda criada com sucesso!')
} catch (error) {
  if (error.response?.status === 401) {
    // Redirecionar para login
  } else {
    toast.error(error.response?.data?.detail || 'Erro desconhecido')
  }
}
```

### Backend:
```python
from fastapi import HTTPException

# Exceções customizadas
class TrelloError(Exception):
    pass

# Tratamento em endpoints
@app.post("/demandas")
async def criar_demanda(demanda: DemandaCreate):
    try:
        # Salvar no banco
        nova_demanda = crud.criar_demanda(db, demanda)
        
        # Tentar criar no Trello
        try:
            card = trello_service.criar_card(nova_demanda)
        except TrelloError as e:
            # Log mas não falha a operação
            logger.error(f"Erro no Trello: {e}")
            # Adicionar à fila de retry
            
        return nova_demanda
        
    except Exception as e:
        logger.exception("Erro ao criar demanda")
        raise HTTPException(status_code=500, detail="Erro interno")
```

---

## 📚 DOCUMENTAÇÃO ADICIONAL

### API Documentation:
- FastAPI gera automaticamente: `/docs` (Swagger UI)
- ReDoc disponível em: `/redoc`
- Todos os endpoints documentados com exemplos

### README.md do Projeto:
- Instruções de instalação
- Como rodar localmente
- Variáveis de ambiente necessárias
- Comandos úteis
- Arquitetura (diagrama)
- Como contribuir

---

## ✅ CHECKLIST DE QUALIDADE

Antes de considerar cada fase concluída:

- [ ] Código comentado em português
- [ ] Validações frontend e backend
- [ ] Tratamento de erros implementado
- [ ] Loading states visíveis
- [ ] Feedback visual ao usuário
- [ ] Responsivo (mobile/tablet/desktop)
- [ ] Acessibilidade básica (labels, alt text)
- [ ] Performance aceitável (<3s load)
- [ ] Sem console.errors no browser
- [ ] Testado manualmente casos de uso principais
- [ ] Testado cenários de erro
- [ ] Git commit com mensagem clara

---

## 🎓 RECURSOS DE APRENDIZADO

### Para FastAPI:
- Docs oficiais: https://fastapi.tiangolo.com
- Tutorial completo: https://fastapi.tiangolo.com/tutorial/

### Para React:
- Docs oficiais: https://react.dev
- React Query: https://tanstack.com/query/latest
- shadcn/ui: https://ui.shadcn.com

### Para Trello API:
- Docs: https://developer.atlassian.com/cloud/trello/rest/
- py-trello: https://github.com/sarumont/py-trello

### Para WPPConnect:
- GitHub: https://github.com/wppconnect-team/wppconnect-server
- Docs API: https://wppconnect-team.github.io/wppconnect-server/

---

## 🎯 OBJETIVOS DE PERFORMANCE

### Frontend:
- First Contentful Paint: <1.5s
- Time to Interactive: <3s
- Lighthouse Score: >90

### Backend:
- Response time (GET): <200ms
- Response time (POST): <500ms
- Suporte: 50 requests simultâneas

### Database:
- Queries otimizadas (índices)
- N+1 queries evitadas
- Conexão pool configurada

---

## 🔄 FLUXO COMPLETO DE UMA DEMANDA

1. **Usuário loga no sistema**
   - Frontend valida credenciais via API
   - Recebe JWT token
   - Redireciona para dashboard

2. **Usuário clica em "Nova Demanda"**
   - Formulário carrega dropdowns do banco
   - Secretarias filtradas por cliente do usuário

3. **Usuário preenche e envia formulário**
   - Frontend valida campos (React Hook Form + Zod)
   - Upload de arquivos para servidor
   - POST para `/api/demandas`

4. **Backend processa**
   - Valida dados novamente
   - Salva no PostgreSQL
   - Cria card no Trello
   - Anexa arquivos no Trello
   - Envia notificação WhatsApp
   - Registra logs
   - Retorna demanda criada

5. **Frontend recebe resposta**
   - Mostra toast de sucesso
   - Redireciona para lista de demandas
   - Lista atualizada automaticamente (React Query)

6. **Cliente vê notificação no WhatsApp**
   - Mensagem formatada com detalhes
   - Link para acessar card no Trello

7. **Usuário pode editar demanda**
   - Abre formulário preenchido
   - Modifica campos permitidos
   - Salva alterações
   - Card no Trello é atualizado
   - Nova notificação enviada (opcional)

---

## 🎨 MOCKUPS DE REFERÊNCIA (Descrição)

### Tela de Login:
- Centro da tela: Card com sombra
- Logo do sistema no topo
- Campos: username, password
- Checkbox "Lembrar-me"
- Botão "Entrar" (azul, full width)
- reCAPTCHA badge
- Background: gradiente suave

### Dashboard:
- Sidebar esquerda (navegação)
- Header no topo (nome usuário, logout)
- Grid de cards 3x1:
  - Total de demandas abertas
  - Total em andamento
  - Total concluídas
- Gráfico de barras (evolução mensal)
- Tabela: "Últimas demandas"

### Formulário de Demanda:
- Layout em 2 colunas (desktop)
- Cards agrupando campos relacionados
- Dropdowns com busca
- Date picker moderno
- Área de upload com drag-and-drop
- Preview dos arquivos
- Botões: "Cancelar" e "Criar Demanda"

### Lista de Demandas:
- Filtros no topo (expansível)
- Tabela responsiva
- Paginação no rodapé
- Badges coloridos (status, prioridade)
- Ações: ícones com tooltip

### Relatórios:
- Sidebar de filtros (esquerda)
- Área principal: cards de métricas
- Abas: Tabelas | Gráficos
- Botões de exportação no canto

---

## 💡 DICAS PARA O CURSOR/VSCODE

### Prompts Úteis:

1. **"Crie o componente FormularioDemanda seguindo as especificações do PROJECT_SPEC.md"**
   
2. **"Implemente o endpoint POST /api/demandas conforme documentado, incluindo validações e integração Trello"**

3. **"Adicione tratamento de erros ao serviço de WhatsApp seguindo os padrões do projeto"**

4. **"Crie a tabela demandas no SQLAlchemy baseado no modelo de dados especificado"**

5. **"Implemente os filtros do relatório com as tecnologias definidas na stack"**

### Estrutura de Pastas Esperada pelo Cursor:
- Mantenha a organização definida
- Comentários explicativos em cada arquivo
- Imports organizados (lib externos, lib internas, relativos)
- Constantes no topo dos arquivos

---

## 🚨 AVISOS IMPORTANTES

1. **NUNCA commite o arquivo .env**
2. **Sempre valide dados no backend** (mesmo que frontend valide)
3. **Teste integrações com dados mock primeiro**
4. **Crie backups antes de migrations**
5. **Use transactions para operações críticas**
6. **Log de erros mas não exponha detalhes ao usuário**
7. **Rate limiting em endpoints públicos**
8. **Sanitize file names antes de salvar**

---

## 📞 PRÓXIMOS PASSOS

Após ler esta especificação:

1. **Configure o ambiente de desenvolvimento**
2. **Clone/crie a estrutura de pastas**
3. **Leia o FRONTEND_GUIDE.md para começar o frontend**
4. **Depois leia o BACKEND_GUIDE.md**
5. **Siga as fases em ordem**
6. **Teste cada funcionalidade antes de prosseguir**

---

## 🎉 BOA SORTE!

Este projeto será incrível! Qualquer dúvida, releia a especificação ou busque na documentação oficial das tecnologias.

**Lembre-se:** Código limpo > Código rápido. Faça certo da primeira vez! 🚀

---

**Versão:** 1.0  
**Data:** Novembro 2025  
**Autor:** Especificação criada para desenvolvimento com Cursor/VSCode
