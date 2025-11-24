# 🎯 CONFIGURAÇÃO TRELLO - RESUMO DA IMPLEMENTAÇÃO

## ✅ STATUS: BACKEND 100% COMPLETO

---

## 📝 **O QUE FOI IMPLEMENTADO**

### **1. BANCO DE DADOS** ✅ COMPLETO

#### ✅ Migration 005: Campo Links de Referência
- **Arquivo**: `backend/alembic/versions/005_add_links_referencia_to_demandas.py`
- **Alteração**: Adiciona campo `links_referencia` (TEXT/JSON) na tabela `demandas`
- **Objetivo**: Permitir que usuários incluam links de referência nas demandas

#### ✅ Migration 006: Tabelas de Configuração Trello
- **Arquivo**: `backend/alembic/versions/006_create_configuracao_trello_tables.py`
- **Tabelas Criadas**:
  - `configuracoes_trello`: Credenciais, board e lista
  - `etiquetas_trello_cliente`: Vinculação de etiquetas a clientes

---

### **2. MODELS BACKEND** ✅ COMPLETO

#### ✅ Model: `Demanda`
- **Arquivo**: `backend/app/models/demanda.py`
- **Alteração**: Adicionado campo `links_referencia: Column(Text)`

#### ✅ Model: `ConfiguracaoTrello`
- **Arquivo**: `backend/app/models/configuracao_trello.py`
- **Campos**:
  - `api_key`: API Key do Trello
  - `token`: Token de autenticação
  - `board_id`: ID do Board
  - `board_nome`: Nome do Board (cache)
  - `lista_id`: ID da Lista
  - `lista_nome`: Nome da Lista (cache)
  - `ativo`: Boolean (apenas uma ativa)

#### ✅ Model: `EtiquetaTrelloCliente`
- **Arquivo**: `backend/app/models/etiqueta_trello_cliente.py`
- **Campos**:
  - `cliente_id`: Foreign Key para clientes
  - `etiqueta_trello_id`: ID da label no Trello
  - `etiqueta_nome`: Nome da etiqueta
  - `etiqueta_cor`: Cor da etiqueta
  - `ativo`: Boolean

#### ✅ Model: `Cliente`
- **Arquivo**: `backend/app/models/cliente.py`
- **Alteração**: Adicionado relacionamento `etiqueta_trello`

---

### **3. SCHEMAS PYDANTIC** ✅ COMPLETO

#### ✅ Schemas: Configuração Trello
- **Arquivo**: `backend/app/schemas/configuracao_trello.py`
- **Schemas**:
  - `ConfiguracaoTrelloCreate`
  - `ConfiguracaoTrelloUpdate`
  - `ConfiguracaoTrelloResponse`
  - `ConfiguracaoTrelloTest`
  - `TrelloBoardInfo`
  - `TrelloListaInfo`
  - `TrelloEtiquetaInfo`

#### ✅ Schemas: Etiquetas Trello
- **Arquivo**: `backend/app/schemas/etiqueta_trello_cliente.py`
- **Schemas**:
  - `EtiquetaTrelloClienteCreate`
  - `EtiquetaTrelloClienteUpdate`
  - `EtiquetaTrelloClienteResponse`
  - `EtiquetaTrelloDisponivel`

---

### **4. ENDPOINTS API** ✅ COMPLETO

#### ✅ Endpoints: Configuração Trello
- **Arquivo**: `backend/app/api/endpoints/trello_config.py`
- **Rotas**:
  - `POST /api/trello-config/` - Salvar configuração
  - `GET /api/trello-config/ativa` - Buscar configuração ativa
  - `POST /api/trello-config/testar` - Testar conexão
  - `GET /api/trello-config/boards/{board_id}/listas` - Listar listas
  - `GET /api/trello-config/boards/{board_id}/etiquetas` - Listar etiquetas
  - `PATCH /api/trello-config/{config_id}` - Atualizar configuração
  - `DELETE /api/trello-config/{config_id}` - Deletar configuração

#### ✅ Endpoints: Etiquetas Trello
- **Arquivo**: `backend/app/api/endpoints/trello_etiquetas.py`
- **Rotas**:
  - `POST /api/trello-etiquetas/` - Vincular etiqueta a cliente
  - `GET /api/trello-etiquetas/` - Listar todas as etiquetas
  - `GET /api/trello-etiquetas/cliente/{cliente_id}` - Buscar etiqueta de cliente
  - `PATCH /api/trello-etiquetas/{etiqueta_id}` - Atualizar etiqueta
  - `DELETE /api/trello-etiquetas/{etiqueta_id}` - Deletar etiqueta
  - `POST /api/trello-etiquetas/{etiqueta_id}/desativar` - Desativar etiqueta
  - `POST /api/trello-etiquetas/{etiqueta_id}/ativar` - Ativar etiqueta

---

### **5. SERVIÇO TRELLO** ✅ COMPLETO

#### ✅ TrelloService Atualizado
- **Arquivo**: `backend/app/services/trello.py`
- **Alterações**:
  - ✅ Inicialização agora usa `ConfiguracaoTrello` do banco (não mais `.env`)
  - ✅ Requer `db: Session` no construtor
  - ✅ Método `criar_card()` atualizado com:
    - **Título**: `"Nome do Cliente - Título da Demanda"`
    - **Descrição**: Inclui links de referência
    - **Etiqueta**: Aplica automaticamente etiqueta do cliente
    - **Anexos**: Anexa imagens ao card
    - **Due Date**: Define prazo da demanda

---

### **6. INTEGRAÇÃO NO MAIN** ✅ COMPLETO

#### ✅ Routers Registrados
- **Arquivo**: `backend/app/main.py`
- **Imports**:
  ```python
  from app.api.endpoints import (
      # ... outros endpoints ...
      trello_config,
      trello_etiquetas
  )
  ```
- **Routers**:
  ```python
  app.include_router(trello_config.router)
  app.include_router(trello_etiquetas.router)
  ```

---

## 🎯 **FUNCIONALIDADES IMPLEMENTADAS**

### **Criação de Card no Trello**

Quando uma demanda é criada no sistema:

```python
# Exemplo de uso
trello_service = TrelloService(db)
card = await trello_service.criar_card(demanda)

# Card criado com:
# - Título: "RUSSAS - Criação de um card teste"
# - Descrição: Detalhamento + Links + Solicitante
# - Etiqueta: Etiqueta do cliente RUSSAS (ex: verde)
# - Anexos: Todas as imagens anexadas
# - Prazo: Due date definido
```

---

### **Formato do Título**
✅ **"Nome do Cliente - TIPO DE DEMANDA - Título da Demanda"**

Exemplo:
```
RUSSAS - DESIGN - Criação de um card teste
RUSSAS - DESENVOLVIMENTO - Sistema de gestão
Prefeitura - CONSULTORIA - Planejamento estratégico
```

---

### **Descrição do Card**

```markdown
**Secretaria:** Secretaria de Comunicação
**Tipo:** Design
**Prioridade:** Alta
**Prazo:** 30/11/2025

**Descrição:**
Criar um novo card no Trello para testar a integração...

**Links de Referência:**
- [Documentação](https://exemplo.com/doc)
- [Referência Visual](https://exemplo.com/img)

**Solicitante:** João Silva
**Email:** joao.silva@exemplo.com

---
**ID da Demanda:** uuid-da-demanda
**Status:** aberta
```

---

### **Etiquetas Automáticas**

Cada cliente pode ter uma etiqueta configurada:

| Cliente | Etiqueta | Cor |
|---------|----------|-----|
| RUSSAS | RUSSAS | Verde |
| Prefeitura | PREF | Azul |
| Câmara | CAM | Laranja |

Quando uma demanda do cliente RUSSAS é criada:
- ✅ Etiqueta "RUSSAS" (verde) é aplicada automaticamente

---

## 📋 **PENDENTE: FRONTEND**

### **Páginas a Criar**

1. **`frontend/src/pages/admin/ConfiguracaoTrello.jsx`**
   - Interface para configurar credenciais
   - Testar conexão
   - Selecionar board e lista

2. **`frontend/src/pages/admin/EtiquetasTrelloClientes.jsx`**
   - Gerenciar etiquetas por cliente
   - Listar clientes
   - Vincular etiquetas do Trello

3. **Atualizar `frontend/src/pages/NovaDemanda.jsx`**
   - Adicionar campo "Links de Referência"
   - Posicionado acima do upload de imagens
   - Suporte a múltiplos links

---

### **Rotas a Adicionar**

```jsx
// frontend/src/App.jsx

<Route path="/admin/trello-config" element={<ConfiguracaoTrello />} />
<Route path="/admin/trello-etiquetas" element={<EtiquetasTrelloClientes />} />
```

---

### **Menu a Atualizar**

```jsx
// frontend/src/components/Sidebar.jsx

// Seção Master
{
  titulo: 'Configurações Trello',
  icon: <IntegrationInstructions />,
  items: [
    { nome: 'Configuração Geral', path: '/admin/trello-config' },
    { nome: 'Etiquetas por Cliente', path: '/admin/trello-etiquetas' }
  ]
}
```

---

## ✅ **CHECKLIST DE IMPLANTAÇÃO**

### **BANCO DE DADOS**
- [ ] Executar migrations no local: `alembic upgrade head`
- [ ] Executar migrations no VPS (via SSH)

### **BACKEND**
- [x] Models criados ✅
- [x] Schemas criados ✅
- [x] Endpoints criados ✅
- [x] TrelloService atualizado ✅
- [x] Routers registrados no main.py ✅

### **FRONTEND**
- [ ] Criar página ConfiguracaoTrello.jsx
- [ ] Criar página EtiquetasTrelloClientes.jsx
- [ ] Adicionar campo Links de Referência em NovaDemanda.jsx
- [ ] Adicionar rotas no App.jsx
- [ ] Atualizar menu Sidebar.jsx

### **TESTES**
- [ ] Testar conexão com Trello
- [ ] Testar seleção de board e lista
- [ ] Testar vinculação de etiquetas
- [ ] Criar demanda de teste
- [ ] Verificar card criado no Trello
- [ ] Validar título do card
- [ ] Validar descrição com links
- [ ] Validar etiqueta aplicada
- [ ] Validar anexos

---

## 🚀 **PRÓXIMOS PASSOS**

1. ✅ **Executar migrations** no ambiente local
2. ✅ **Criar páginas frontend** de configuração
3. ✅ **Adicionar campo de links** no formulário de demanda
4. ✅ **Testar integração** completa
5. ✅ **Executar migrations no VPS**
6. ✅ **Deploy** para produção

---

## 📞 **INFORMAÇÕES NECESSÁRIAS**

Para configurar o Trello via interface:

1. **API Key**
   - Acessar: https://trello.com/app-key
   - Copiar API Key

2. **Token**
   - Clicar em "Token" na mesma página
   - Autorizar aplicação
   - Copiar Token

3. **Board e Lista**
   - Serão selecionados via interface após teste de conexão
   - Sistema lista automaticamente boards e listas disponíveis

---

## 📊 **FLUXO COMPLETO**

```
1. MASTER acessa "Configurações Master" → "Trello" → "Configuração Geral"
   ↓
2. Insere API Key + Token
   ↓
3. Clica "Testar Conexão" → Sistema lista Boards
   ↓
4. Seleciona Board → Sistema lista Listas
   ↓
5. Seleciona Lista → Salva configuração
   ↓
6. Acessa "Etiquetas por Cliente"
   ↓
7. Para cada cliente:
   - Seleciona cliente
   - Seleciona etiqueta do Trello
   - Salva vinculação
   ↓
8. PRONTO! Demandas criadas automaticamente geram cards com:
   ✅ Título: Nome do Cliente - Título da Demanda
   ✅ Descrição: Detalhamento + Links + Anexos
   ✅ Etiqueta: Etiqueta do Cliente
   ✅ Lista: Lista configurada
   ✅ Prazo: Due date definido
```

---

**Backend 100% COMPLETO** ✅  
**Frontend em desenvolvimento** 🚧  
**Migrations prontas para execução** ✅

