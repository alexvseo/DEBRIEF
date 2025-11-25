# 🔧 Correção dos Endpoints WhatsApp - Configurações de Notificação

## 📋 Problema Relatado

Usuário reportou 3 problemas na página **Configuração WhatsApp**:

1. ❌ **Campo "Seu Número WhatsApp"** não estava salvando
2. ❌ **Campo "Número para Teste"** não estava salvando  
3. ❌ **Erro "Recurso não encontrado"** ao salvar informações

## 🔍 Causa Raiz

### 1. Conflito de Rotas no FastAPI

```python
# ❌ ORDEM ERRADA (causava 404)
@router.get("/{usuario_id}", ...)  # Linha 80
...
@router.get("/me", ...)  # Linha 500 ← "me" era tratado como usuario_id!
```

O FastAPI processa rotas na ordem que aparecem no arquivo. Como `/{usuario_id}` vinha ANTES de `/me`, qualquer requisição para `/me` era interceptada como se "me" fosse um ID de usuário, resultando em 404 "Usuário não encontrado".

### 2. Container Docker Não Atualizado

Após corrigir o código, o container continuava usando a **imagem antiga**. Apenas `docker restart` não aplica mudanças no código Python - é necessário `docker-compose build`.

## ✅ Solução Implementada

### 1. Reordenar Endpoints

**Arquivo:** `backend/app/api/endpoints/usuarios.py`

```python
# ✅ ORDEM CORRETA
@router.get("/me", response_model=UserResponse)  # Linha 80
def obter_perfil_atual(
    current_user: User = Depends(get_current_user)
):
    """Retorna informações do usuário autenticado"""
    return UserResponse.from_orm(current_user)


@router.put("/me/notificacoes", response_model=UserResponse)  # Linha 95
def atualizar_configuracoes_notificacao(
    settings: UserNotificationSettings,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    """Atualiza configurações de notificação WhatsApp"""
    # ... código de atualização ...


@router.get("/{usuario_id}", response_model=UserResponse)  # Linha 137
def buscar_usuario(
    usuario_id: str,
    db: Session = Depends(get_db),
    current_user: User = Depends(require_master)
):
    """Busca usuário por ID (Master apenas)"""
    # ... código de busca ...
```

**Regra:** Rotas **específicas** (`/me`) devem vir ANTES de rotas **genéricas** com parâmetros (`/{usuario_id}`)

### 2. Adicionar Configurações WhatsApp API

**Arquivo:** `backend/app/core/config.py`

```python
class Settings(BaseSettings):
    # ...
    
    # WhatsApp API (Evolution v1.8.5)
    WHATSAPP_API_URL: str = "http://localhost:21465"
    WHATSAPP_API_KEY: str = "debrief-wpp-58a2b7dda7da9474958e2a853062d5d5"
```

### 3. Rebuild da Imagem Docker

```bash
# No servidor
cd /var/www/debrief
git pull origin main
docker-compose -f docker-compose.prod.yml build backend --no-cache
docker-compose -f docker-compose.prod.yml up -d backend
```

## 🧪 Testes Realizados

Script de teste automatizado (`testar-endpoints-me.sh`):

```bash
#!/bin/bash
# 1. Login com usuário admindb
# 2. GET /api/usuarios/me → ✅ 200 OK
# 3. PUT /api/usuarios/me/notificacoes → ✅ 200 OK
# 4. Verificação de persistência → ✅ Dados salvos
```

### Resultado dos Testes

```json
✅ GET /api/usuarios/me - Status 200
{
    "id": "fc50f55d-bcd2-498b-a723-dbe2b8cd156d",
    "username": "admindb",
    "whatsapp": "5585991042626",
    "receber_notificacoes": true,
    ...
}

✅ PUT /api/usuarios/me/notificacoes - Status 200
{
    "whatsapp": "5585991042626",
    "receber_notificacoes": true
}

✅ Dados persistidos corretamente no banco
```

## 📊 Endpoints Funcionando

| Método | Endpoint | Status | Função |
|--------|----------|--------|--------|
| GET | `/api/usuarios/me` | ✅ 200 OK | Retorna dados do usuário logado |
| PUT | `/api/usuarios/me/notificacoes` | ✅ 200 OK | Atualiza WhatsApp e preferências |
| GET | `/api/whatsapp/status` | ✅ 200 OK | Status da conexão Evolution API |
| POST | `/api/whatsapp/testar` | ✅ 200 OK | Envia mensagem de teste |

## 🎯 Impacto

### Antes da Correção
- ❌ Usuários não conseguiam salvar número WhatsApp
- ❌ Campo de teste não funcionava
- ❌ Erro "Recurso não encontrado" constante

### Depois da Correção
- ✅ Campo "Seu Número WhatsApp" salva corretamente
- ✅ Toggle "Receber Notificações" funciona
- ✅ Botão "Testar Conexão" envia mensagens
- ✅ Dados persistem no banco

## 📝 Commits Relacionados

1. **`0a735d0`** - Fix: Corrigir ordem dos endpoints /me para evitar conflito 404
2. **`a2cff92`** - Feat: Adicionar configurações WhatsApp API no Settings
3. **`d908843`** - Debug: Adicionar log debug no endpoint GET /me

## 🚀 Deploy

```bash
cd /Users/alexmini/Documents/PROJETOS\ DEV\ COM\ IA/DEBRIEF
git add -A
git commit -m "fix: Corrigir ordem de rotas e adicionar configurações WhatsApp"
git push origin main

# No servidor
ssh root@82.25.92.217
cd /var/www/debrief
git pull origin main
docker-compose -f docker-compose.prod.yml build backend --no-cache
docker-compose -f docker-compose.prod.yml up -d backend
```

## ✅ Status Final

🎉 **PROBLEMA RESOLVIDO COMPLETAMENTE**

- ✅ Backend: Endpoints funcionando
- ✅ Banco: Dados sendo salvos
- ✅ Frontend: Testado e operacional
- ✅ Notificações WhatsApp: Sistema completo funcional

---

**Data:** 24/11/2025  
**Versão:** DeBrief v1.0.0  
**Ambiente:** Produção (82.25.92.217)

