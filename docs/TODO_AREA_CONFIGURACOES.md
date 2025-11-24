# 📋 TODO - Área de Configurações

Este documento lista todas as funcionalidades da área de configurações que precisam ser verificadas e testadas.

## ✅ Status Geral

- ✅ **Gerenciar Clientes** - Implementado e funcional
- ✅ **Gerenciar Secretarias** - Implementado e funcional  
- ✅ **Gerenciar Usuários** - Implementado e funcional
- ⚠️ **Gerenciar Demandas** - Implementado, mas falta verificar deletar/cancelar

---

## 1. 📦 Gerenciar Clientes

**Localização:** `frontend/src/pages/Configuracoes.jsx`

### ✅ Adicionar Cliente
- **Função:** `salvarCliente()`
- **Endpoint:** `POST /clientes/`
- **Status:** ✅ Implementado
- **Validações:**
  - Nome obrigatório (trim)
  - WhatsApp Group ID opcional (formato: `@g.us`)
  - Trello Member ID opcional
  - Campos vazios convertidos para `null`
- **Testes necessários:**
  - [ ] Criar cliente com todos os campos
  - [ ] Criar cliente apenas com nome
  - [ ] Validar duplicação de nome
  - [ ] Validar formato WhatsApp ID

### ✅ Editar Cliente
- **Função:** `salvarCliente()` (com `modalCliente.item`)
- **Endpoint:** `PUT /clientes/{id}`
- **Status:** ✅ Implementado
- **Testes necessários:**
  - [ ] Editar nome do cliente
  - [ ] Editar WhatsApp Group ID
  - [ ] Editar Trello Member ID
  - [ ] Validar que não permite duplicação

### ✅ Deletar Cliente
- **Função:** `toggleCliente()`
- **Endpoint:** `DELETE /clientes/{id}` (desativa)
- **Status:** ✅ Implementado
- **Observação:** Usa soft delete (desativa em vez de deletar)
- **Testes necessários:**
  - [ ] Desativar cliente ativo
  - [ ] Reativar cliente inativo
  - [ ] Verificar se cliente desativado não aparece em dropdowns

---

## 2. 🏢 Gerenciar Secretarias

**Localização:** `frontend/src/pages/Configuracoes.jsx`

### ✅ Adicionar Secretaria
- **Função:** `salvarSecretaria()`
- **Endpoint:** `POST /secretarias/`
- **Status:** ✅ Implementado
- **Validações:**
  - Nome obrigatório (trim)
  - Cliente obrigatório (cliente_id)
  - Validação no frontend antes de enviar
- **Testes necessários:**
  - [ ] Criar secretaria com cliente selecionado
  - [ ] Validar que não permite criar sem cliente
  - [ ] Validar nome único por cliente
  - [ ] Verificar relacionamento com cliente

### ✅ Editar Secretaria
- **Função:** `salvarSecretaria()` (com `modalSecretaria.item`)
- **Endpoint:** `PUT /secretarias/{id}`
- **Status:** ✅ Implementado
- **Observação:** Não permite alterar cliente vinculado
- **Testes necessários:**
  - [ ] Editar nome da secretaria
  - [ ] Verificar que cliente não pode ser alterado
  - [ ] Validar nome único por cliente

### ✅ Deletar Secretaria
- **Função:** `toggleSecretaria()`
- **Endpoint:** `DELETE /secretarias/{id}` (desativa)
- **Status:** ✅ Implementado
- **Observação:** Usa soft delete (desativa em vez de deletar)
- **Testes necessários:**
  - [ ] Desativar secretaria ativa
  - [ ] Reativar secretaria inativa
  - [ ] Verificar se secretaria desativada não aparece em formulários

---

## 3. 👥 Gerenciar Usuários

**Localização:** `frontend/src/pages/GerenciarUsuarios.jsx`

### ✅ Adicionar Usuário
- **Função:** `salvarUsuario()`
- **Endpoint:** `POST /api/usuarios/`
- **Status:** ✅ Implementado
- **Campos:**
  - username (obrigatório)
  - email (obrigatório)
  - nome_completo (obrigatório)
  - password (obrigatório na criação)
  - tipo (master/cliente)
  - cliente_id (se tipo = cliente)
- **Testes necessários:**
  - [ ] Criar usuário master
  - [ ] Criar usuário cliente (com cliente_id)
  - [ ] Validar email único
  - [ ] Validar username único
  - [ ] Validar senha forte

### ✅ Editar Usuário
- **Função:** `salvarUsuario()` (com `modalUsuario.item`)
- **Endpoint:** `PUT /api/usuarios/{id}`
- **Status:** ✅ Implementado
- **Observação:** Senha é opcional na edição (não envia se vazia)
- **Testes necessários:**
  - [ ] Editar dados do usuário
  - [ ] Alterar tipo de usuário
  - [ ] Alterar senha (opcional)
  - [ ] Editar sem alterar senha

### ✅ Deletar Usuário
- **Função:** `toggleUsuario()`
- **Endpoint:** `DELETE /api/usuarios/{id}` (desativa)
- **Status:** ✅ Implementado
- **Observação:** Usa soft delete (desativa em vez de deletar)
- **Testes necessários:**
  - [ ] Desativar usuário ativo
  - [ ] Reativar usuário inativo
  - [ ] Verificar que usuário desativado não pode fazer login

### 🔑 Funcionalidade Extra: Resetar Senha
- **Função:** `resetarSenha()`
- **Endpoint:** `POST /api/usuarios/{id}/reset-password`
- **Status:** ✅ Implementado
- **Testes necessários:**
  - [ ] Resetar senha de usuário
  - [ ] Validar nova senha

---

## 4. 📝 Gerenciar Demandas

**Localização:** `frontend/src/components/forms/DemandaForm.jsx`

### ✅ Adicionar Demanda
- **Função:** `onSubmit()` via `demandaService.criar()`
- **Endpoint:** `POST /api/demandas`
- **Status:** ✅ Implementado
- **Campos obrigatórios:**
  - secretaria_id
  - nome
  - tipo_demanda_id
  - prioridade_id
  - descricao
  - prazo_final
- **Funcionalidades:**
  - Upload de arquivos (múltiplos)
  - Validação com Zod
  - Formatação de datas
- **Testes necessários:**
  - [ ] Criar demanda com todos os campos
  - [ ] Criar demanda com arquivos
  - [ ] Validar campos obrigatórios
  - [ ] Validar formato de data
  - [ ] Validar tamanho de arquivos

### ✅ Editar Demanda
- **Função:** `onSubmit()` via `demandaService.atualizar()`
- **Endpoint:** `PUT /api/demandas/{id}`
- **Status:** ✅ Implementado
- **Testes necessários:**
  - [ ] Editar dados da demanda
  - [ ] Adicionar novos arquivos
  - [ ] Remover arquivos existentes
  - [ ] Alterar status da demanda

### ⚠️ Deletar/Cancelar Demanda
- **Status:** ⚠️ Verificar implementação
- **Observação:** Demandas podem ser canceladas (status = 'cancelada')
- **Testes necessários:**
  - [ ] Verificar se existe botão/opção para cancelar demanda
  - [ ] Verificar endpoint de cancelamento
  - [ ] Verificar se demanda cancelada não pode ser editada
  - [ ] Verificar se demanda cancelada aparece na listagem

---

## 📊 Resumo de Implementação

| Funcionalidade | Adicionar | Editar | Deletar | Status |
|---------------|-----------|--------|---------|--------|
| **Clientes** | ✅ | ✅ | ✅ | ✅ Completo |
| **Secretarias** | ✅ | ✅ | ✅ | ✅ Completo |
| **Usuários** | ✅ | ✅ | ✅ | ✅ Completo |
| **Demandas** | ✅ | ✅ | ⚠️ | ⚠️ Verificar deletar |

---

## 🔍 Próximos Passos

1. **Testar todas as funcionalidades** listadas acima
2. **Verificar funcionalidade de deletar/cancelar demanda**
3. **Documentar bugs encontrados**
4. **Corrigir problemas identificados**
5. **Adicionar testes automatizados** (opcional)

---

## 📝 Notas

- Todas as operações de "deletar" usam **soft delete** (desativa em vez de deletar)
- Validações são feitas tanto no **frontend** quanto no **backend**
- Mensagens de erro são exibidas de forma clara para o usuário
- Todas as operações recarregam a lista após sucesso

---

**Última atualização:** 2025-01-XX
**Responsável:** Equipe de Desenvolvimento

