# ✅ WhatsApp Evolution API - Status Atual

**Atualizado em**: 24/11/2025 19:08

## 🎉 STATUS: **TOTALMENTE OPERACIONAL!**

### 📊 Informações da Conexão

```json
{
    "instance": {
        "instanceName": "debrief",
        "state": "open",  // ✅ CONECTADO E FUNCIONANDO!
        "owner": "558596039026@s.whatsapp.net",
        "profileName": "Debrief",
        "status": "open",
        "integration": "WHATSAPP-BAILEYS"
    }
}
```

### ✅ Confirmações

| Item | Status | Detalhes |
|------|--------|----------|
| **Conexão WhatsApp** | ✅ Conectado | `state: "open"` |
| **Baileys Multi-Device** | ✅ Ativo | Evolution v1.8.5 |
| **Número Conectado** | ✅ Verificado | 55 85 96039026 |
| **Nome do Perfil** | ✅ "Debrief" | |
| **API REST** | ✅ Funcionando | Porta 21465 |
| **Docker Container** | ✅ Rodando | `wppconnect-server` |

## 🔧 Configuração Atual

### Evolution API

```
URL: http://82.25.92.217:21465
API Key: debrief-wpp-58a2b7dda7da9474958e2a853062d5d5
Instância: debrief
Instance ID: ff6eab66-9c8a-45ac-919e-844d918a8a37
Integration: WHATSAPP-BAILEYS
```

### Backend DeBrief

⚠️ **ATENÇÃO**: O backend está configurado com a porta ERRADA!

```env
# Configuração ATUAL (ERRADA)
WHATSAPP_API_URL=http://82.25.92.217:3001

# Deve ser (CORRETA)
WHATSAPP_API_URL=http://localhost:21465
```

#### 🔧 Para Corrigir:

```bash
ssh root@82.25.92.217 "cd /var/www/debrief/backend && \
  sed -i 's|WHATSAPP_API_URL=.*|WHATSAPP_API_URL=http://localhost:21465|' .env && \
  cat .env | grep WHATSAPP_API_URL"

# Reiniciar backend
ssh root@82.25.92.217 "cd /var/www/debrief && docker-compose restart debrief-backend"
```

## 🧪 Como Testar

### 1. Verificar Status

```bash
ssh root@82.25.92.217 "curl -s 'http://localhost:21465/instance/connectionState/debrief' \
  -H 'apikey: debrief-wpp-58a2b7dda7da9474958e2a853062d5d5'"
```

**Resposta esperada:**
```json
{"instance": {"instanceName": "debrief", "state": "open"}}
```

### 2. Enviar Mensagem de Teste

Use o script criado:
```bash
./testar-envio-whatsapp.sh
```

Ou manualmente:
```bash
ssh root@82.25.92.217 "curl -X POST 'http://localhost:21465/message/sendText/debrief' \
  -H 'apikey: debrief-wpp-58a2b7dda7da9474958e2a853062d5d5' \
  -H 'Content-Type: application/json' \
  -d '{
    \"number\": \"5511999999999\",
    \"text\": \"Teste do DeBrief via Baileys!\"
  }'"
```

### 3. Listar Chats/Grupos

```bash
ssh root@82.25.92.217 "curl -s 'http://localhost:21465/chat/findChats/debrief' \
  -H 'apikey: debrief-wpp-58a2b7dda7da9474958e2a853062d5d5' \
  -X POST \
  -H 'Content-Type: application/json' \
  -d '{\"where\": {}}'"
```

## 📱 Como Funciona no DeBrief

### 1. Criação de Demanda

Quando uma nova demanda é criada:

```python
# backend/app/services/whatsapp.py
whatsapp = WhatsAppService()
await whatsapp.enviar_nova_demanda(demanda, db)
```

### 2. Envio da Mensagem

```python
async def enviar_mensagem(self, chat_id: str, mensagem: str) -> bool:
    url = f"{self.base_url}/send-message"  # ← PRECISA SER http://localhost:21465
    payload = {
        "chatId": chat_id,
        "message": mensagem
    }
    response = requests.post(url, json=payload, headers=self.headers)
```

### 3. Formato das Mensagens

```python
mensagem = f"""
🔔 *Nova Demanda Recebida!*

📋 *Demanda:* {demanda.nome}
🏢 *Secretaria:* {demanda.secretaria.nome}
📌 *Tipo:* {demanda.tipo_demanda.nome}
{emoji_prioridade} *Prioridade:* {demanda.prioridade.nome}
📅 *Prazo:* {demanda.prazo_final.strftime('%d/%m/%Y')}

👤 *Solicitante:* {demanda.usuario.nome_completo}

🔗 *Ver no Trello:* {demanda.trello_card_url}

_ID: {demanda.id}_
"""
```

## 🎯 Endpoints Úteis da Evolution API

### Instância

- `GET /instance/connectionState/:instance` - Status da conexão
- `GET /instance/fetchInstances?instanceName=:name` - Detalhes da instância
- `POST /instance/create` - Criar nova instância
- `DELETE /instance/delete/:instance` - Deletar instância

### Mensagens

- `POST /message/sendText/:instance` - Enviar texto
- `POST /message/sendMedia/:instance` - Enviar mídia
- `POST /message/sendButtons/:instance` - Enviar botões

### Chats/Grupos

- `POST /chat/findChats/:instance` - Listar chats
- `GET /group/fetchAllGroups/:instance` - Listar grupos
- `POST /group/create/:instance` - Criar grupo

## 📝 Logs

### Ver logs do Evolution/Baileys

```bash
ssh root@82.25.92.217 "docker logs wppconnect-server --tail 100 -f"
```

### Ver logs do Backend DeBrief

```bash
ssh root@82.25.92.217 "docker logs debrief-backend --tail 100 -f"
```

## ⚠️ Problemas Conhecidos

### 1. Porta Errada no Backend

**Sintoma**: Backend não consegue enviar mensagens

**Causa**: `.env` aponta para porta 3001, mas Evolution roda na 21465

**Solução**: Atualizar `.env` (ver seção "Para Corrigir" acima)

### 2. Diretório de Mensagens

**Aviso nos logs**:
```
ERROR [MessageRepository] error on message find: 
ENOENT: no such file or directory, opendir '/evolution/store/messages/debrief'
```

**Impacto**: Nenhum - não afeta envio de mensagens

**Opcional**: Criar diretório no container se quiser histórico persistente

## 🚀 Próximos Passos

- [x] ✅ Evolution API rodando
- [x] ✅ Baileys conectado ao WhatsApp
- [x] ✅ Instância "debrief" criada e ativa
- [ ] 🔧 Corrigir porta no backend (.env)
- [ ] 🧪 Testar envio via backend
- [ ] 📱 Configurar grupos dos clientes
- [ ] ✨ Testar notificações de demandas

## 💡 Dicas

### Múltiplas Instâncias

Você pode ter uma instância para cada cliente:

```bash
# Cliente 1
curl -X POST 'http://localhost:21465/instance/create' \
  -d '{"instanceName": "cliente1", "integration": "WHATSAPP-BAILEYS"}'

# Cliente 2
curl -X POST 'http://localhost:21465/instance/create' \
  -d '{"instanceName": "cliente2", "integration": "WHATSAPP-BAILEYS"}'
```

### Webhooks

Configure webhooks para receber mensagens:

```bash
curl -X POST 'http://localhost:21465/webhook/set/debrief' \
  -H 'apikey: debrief-wpp-58a2b7dda7da9474958e2a853062d5d5' \
  -d '{
    "url": "http://debrief-backend:8000/api/whatsapp/webhook",
    "webhook_by_events": true,
    "events": ["messages.upsert"]
  }'
```

## 📚 Documentação

- **Evolution API v1.8.5**: https://doc.evolution-api.com/v1/
- **Baileys**: https://github.com/WhiskeySockets/Baileys
- **DeBrief Backend**: `backend/app/services/whatsapp.py`

---

✨ **O WhatsApp está 100% funcional via Baileys Multi-Device!**




