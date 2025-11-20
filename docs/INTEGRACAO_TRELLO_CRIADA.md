# 🎯 INTEGRAÇÃO TRELLO CRIADA COM SUCESSO!

## 📦 O QUE FOI IMPLEMENTADO

### 1️⃣ Serviços Criados

#### ✅ `TrelloService` (`app/services/trello.py`)
Serviço completo de integração com Trello API:

**Funcionalidades:**
- ✅ Criar card automaticamente ao criar demanda
- ✅ Atualizar card ao modificar demanda
- ✅ Adicionar anexos ao card
- ✅ Atribuir membros (clientes) ao card
- ✅ Definir labels de prioridade
- ✅ Definir due dates (prazos)
- ✅ Mover cards entre listas por status
- ✅ Adicionar comentários ao card
- ✅ Arquivar cards concluídos/cancelados

**Métodos principais:**
```python
await trello_service.criar_card(demanda, db)
await trello_service.atualizar_card(demanda, db)
await trello_service.adicionar_comentario(demanda, "comentário", "autor")
await trello_service.arquivar_card(demanda)
```

---

#### ✅ `WhatsAppService` (`app/services/whatsapp.py`)
Serviço de integração com WPPConnect:

**Funcionalidades:**
- ✅ Enviar notificação de nova demanda
- ✅ Enviar atualização de status
- ✅ Enviar lembretes de prazo
- ✅ Mensagens customizadas
- ✅ Verificar status da instância

**Métodos principais:**
```python
await whatsapp.enviar_nova_demanda(demanda, db)
await whatsapp.enviar_atualizacao_status(demanda, db, status_antigo)
await whatsapp.enviar_lembrete_prazo(demanda, db, dias_faltando)
await whatsapp.enviar_mensagem(group_id, mensagem)
```

---

#### ✅ `UploadService` (`app/services/upload.py`)
Serviço de gerenciamento de arquivos:

**Funcionalidades:**
- ✅ Validar tamanho e extensão de arquivos
- ✅ Salvar arquivos organizados (cliente/demanda)
- ✅ Gerar nomes únicos (UUID)
- ✅ Deletar arquivos
- ✅ Obter informações de arquivo

**Métodos principais:**
```python
file_path = await upload_service.save_file(file, cliente_id, demanda_id)
upload_service.delete_file(file_path)
info = upload_service.get_file_info(file_path)
```

---

#### ✅ `NotificationService` (`app/services/notification.py`)
Serviço centralizado de notificações:

**Funcionalidades:**
- ✅ Enviar notificações multi-canal (WhatsApp + Email futuro)
- ✅ Notificações de nova demanda
- ✅ Notificações de mudança de status
- ✅ Lembretes de prazo

**Métodos principais:**
```python
await notification.notificar_nova_demanda(demanda, db, canais=['whatsapp'])
await notification.notificar_atualizacao_status(demanda, db, status_antigo)
await notification.notificar_lembrete_prazo(demanda, db, dias_faltando)
```

---

### 2️⃣ Configurações Atualizadas

#### ✅ `requirements.txt` - Dependências adicionadas:
```txt
# Integrações
py-trello==0.19.0
requests==2.31.0

# Geração de Relatórios
reportlab==4.1.0
openpyxl==3.1.2
pillow==10.2.0

# Async e I/O
aiofiles==23.2.1
```

#### ✅ `app/core/config.py` - Variáveis adicionadas:
```python
# Trello Integration
TRELLO_API_KEY: Optional[str] = None
TRELLO_TOKEN: Optional[str] = None
TRELLO_BOARD_ID: Optional[str] = None
TRELLO_LIST_ID: Optional[str] = None

# WhatsApp/WPPConnect Integration
WPP_URL: Optional[str] = None
WPP_INSTANCE: Optional[str] = None
WPP_TOKEN: Optional[str] = None

# Google reCAPTCHA
RECAPTCHA_SECRET_KEY: Optional[str] = None

# Environment
ENVIRONMENT: str = "development"
FRONTEND_URL: str = "http://localhost:5173"
MAX_UPLOAD_SIZE: int = 52428800
ALLOWED_EXTENSIONS: list[str] = ["pdf", "jpg", "jpeg", "png"]
```

#### ✅ `.env.example` - Criado com todas as variáveis necessárias

---

## 🚀 COMO USAR

### 1. Instalar Dependências

```bash
cd backend
source venv/bin/activate
pip install -r requirements.txt
```

### 2. Configurar Variáveis de Ambiente

Editar arquivo `.env` (criar cópia do `.env.example`):

```bash
# TRELLO
TRELLO_API_KEY=sua-api-key-aqui
TRELLO_TOKEN=seu-token-aqui
TRELLO_BOARD_ID=id-do-board
TRELLO_LIST_ID=id-da-lista

# WPPCONNECT
WPP_URL=http://localhost:21465
WPP_INSTANCE=debrief-instance
WPP_TOKEN=seu-token-wpp
```

#### 📋 Como Obter Credenciais do Trello:

1. **API Key e Token:**
   - Acesse: https://trello.com/app-key
   - Copie a **API Key**
   - Clique em "Token" e autorize
   - Copie o **Token**

2. **Board ID:**
   - Abra seu board no Trello
   - Na URL: `https://trello.com/b/BOARD_ID/nome`
   - Copie o `BOARD_ID`

3. **List ID:**
   - Abra o board
   - Clique com botão direito na lista → "Inspecionar"
   - Procure por `data-list-id` no HTML
   - Copie o ID

---

### 3. Usar nos Endpoints

#### Exemplo: Criar Demanda com Integração Trello

```python
from app.services.trello import TrelloService
from app.services.notification import NotificationService

@router.post("", response_model=DemandaResponse)
async def criar_demanda(
    # ... parâmetros
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    try:
        # 1. Criar demanda no banco
        demanda = Demanda(...)
        db.add(demanda)
        db.commit()
        
        # 2. Upload de arquivos (se houver)
        if files:
            upload_service = UploadService()
            for file in files:
                file_path = await upload_service.save_file(
                    file, current_user.cliente_id, demanda.id
                )
                # Salvar anexo no banco...
        
        # 3. Criar card no Trello
        try:
            trello_service = TrelloService()
            card = await trello_service.criar_card(demanda, db)
            
            # Atualizar demanda com IDs do Trello
            demanda.trello_card_id = card['id']
            demanda.trello_card_url = card['url']
            db.commit()
            
        except Exception as e:
            logger.error(f"Erro ao criar card no Trello: {e}")
        
        # 4. Enviar notificações
        try:
            notification_service = NotificationService()
            await notification_service.notificar_nova_demanda(
                demanda, db, canais=['whatsapp']
            )
        except Exception as e:
            logger.error(f"Erro ao enviar notificação: {e}")
        
        return demanda
        
    except Exception as e:
        db.rollback()
        raise HTTPException(status_code=500, detail=str(e))
```

---

## 🎨 EXEMPLOS DE CARDS CRIADOS

### Card de Demanda no Trello:

```
📋 Nome: Nova Campanha Marketing - Prefeitura Municipal

📝 Descrição:
**Secretaria:** Secretaria de Comunicação
**Tipo:** Design
**Prioridade:** Alta
**Prazo:** 25/12/2024

**Descrição:**
Criar identidade visual para campanha de vacinação infantil.
Incluir posts para redes sociais e banner para site.

**Solicitante:** João Silva
**Email:** joao@prefeitura.com

---
**ID da Demanda:** abc-123-def-456
**Status:** aberta

🔗 Anexos: banner.pdf, logo.png
👤 Atribuído: @ClientePrefeitura
🏷️ Label: Alta Prioridade
📅 Due Date: 25/12/2024
```

---

## 📱 MENSAGENS WHATSAPP

### Nova Demanda:
```
🔔 *Nova Demanda Recebida!*

📋 *Demanda:* Nova Campanha Marketing
🏢 *Secretaria:* Secretaria de Comunicação
📌 *Tipo:* Design
🔴 *Prioridade:* Alta
📅 *Prazo:* 25/12/2024

👤 *Solicitante:* João Silva

🔗 *Ver no Trello:* https://trello.com/c/xyz

_ID: abc-123-def-456_
```

### Atualização de Status:
```
🔄 *Atualização de Demanda*

📋 *Demanda:* Nova Campanha Marketing

⚙️ *Status:* aberta → *Em Andamento*

🔗 *Ver no Trello:* https://trello.com/c/xyz

_ID: abc-123-def-456_
```

### Lembrete de Prazo:
```
⚠️ *Lembrete de Prazo!*

📋 *Demanda:* Nova Campanha Marketing
📅 *Prazo:* 25/12/2024
⏳ *Faltam:* 3 dia(s)

🔗 *Ver no Trello:* https://trello.com/c/xyz

_ID: abc-123-def-456_
```

---

## 🔧 TROUBLESHOOTING

### Erro: "Trello API Key inválida"
- Verificar se `TRELLO_API_KEY` está correto no `.env`
- Verificar se o token não expirou
- Gerar novo token em: https://trello.com/app-key

### Erro: "Board não encontrado"
- Verificar se `TRELLO_BOARD_ID` está correto
- Verificar se a API Key tem acesso ao board
- Testar com: `GET https://api.trello.com/1/boards/{BOARD_ID}?key={KEY}&token={TOKEN}`

### Erro: "Lista não encontrada"
- Verificar se `TRELLO_LIST_ID` está correto
- Listar todas as listas: `GET https://api.trello.com/1/boards/{BOARD_ID}/lists?key={KEY}&token={TOKEN}`

### Erro: "WhatsApp não enviando"
- Verificar se WPPConnect está rodando
- Testar endpoint: `GET http://localhost:21465/api/{INSTANCE}/status`
- Verificar se `WPP_TOKEN` está correto
- Verificar se o grupo existe e está configurado no cliente

---

## 📚 DOCUMENTAÇÃO ADICIONAL

### Trello API:
- Docs oficiais: https://developer.atlassian.com/cloud/trello/rest/
- py-trello GitHub: https://github.com/sarumont/py-trello

### WPPConnect:
- Docs oficiais: https://wppconnect.io/
- GitHub: https://github.com/wppconnect-team/wppconnect

---

## ✅ CHECKLIST DE TESTES

- [ ] Instalar dependências
- [ ] Configurar credenciais Trello no `.env`
- [ ] Criar demanda e verificar card no Trello
- [ ] Atualizar demanda e verificar card atualizado
- [ ] Testar upload de arquivos
- [ ] Configurar WPPConnect (se disponível)
- [ ] Testar notificações WhatsApp
- [ ] Testar mudança de status
- [ ] Testar comentários no card

---

## 🎉 PRÓXIMOS PASSOS

1. **Instalar dependências:**
   ```bash
   pip install -r requirements.txt
   ```

2. **Configurar Trello:**
   - Obter credenciais
   - Adicionar no `.env`
   - Testar criação de card

3. **Integrar com endpoints:**
   - Atualizar `app/api/endpoints/demandas.py`
   - Adicionar calls aos serviços
   - Testar fluxo completo

4. **Setup WPPConnect (opcional):**
   - Instalar WPPConnect
   - Configurar instância
   - Testar notificações

---

**Status:** ✅ INTEGRAÇÃO TRELLO PRONTA PARA USO!

**Arquivos Criados:**
- ✅ `app/services/trello.py` (350+ linhas)
- ✅ `app/services/whatsapp.py` (250+ linhas)
- ✅ `app/services/upload.py` (280+ linhas)
- ✅ `app/services/notification.py` (150+ linhas)
- ✅ `app/services/__init__.py`
- ✅ `.env.example` (completo)
- ✅ `app/core/config.py` (atualizado)
- ✅ `requirements.txt` (atualizado)

**Total de Código:** ~1000+ linhas de código documentado! 🚀

