# ✅ Evolution API (Baileys) - Funcionando!

## 🎯 Descoberta Principal

**O Evolution API v1.8.5 JÁ USA BAILEYS!** 🎉

Você não precisa instalar o Baileys separadamente. O Evolution API é um wrapper elegante do Baileys Multi-Device com API REST pronta.

## 📊 Status Atual

### ✅ O que está funcionando:

- **Container**: `wppconnect-server` rodando
- **Versão**: Evolution API v1.8.5  
- **Porta**: 21465
- **Integration**: WHATSAPP-BAILEYS (confirmado!)
- **API Key**: `debrief-wpp-58a2b7dda7da9474958e2a853062d5d5`
- **Instância**: `debrief` criada com sucesso

### ⚠️ O que precisa fazer:

- **Escanear QR Code** para conectar ao WhatsApp
- O WhatsApp foi desconectado anteriormente (`device_removed`)

## 🔧 Como o Backend Conecta

O backend **NÃO se conecta automaticamente** ao Evolution/Baileys na inicialização.

```python
# backend/app/services/whatsapp.py
def __init__(self):
    self.base_url = settings.WHATSAPP_API_URL  # http://82.25.92.217:3001
    self.api_key = settings.WHATSAPP_API_KEY
    logger.info("WhatsAppService inicializado")
```

O serviço **só usa** a API quando precisa enviar mensagem:

```python
async def enviar_mensagem(self, chat_id: str, mensagem: str) -> bool:
    url = f"{self.base_url}/send-message"
    response = requests.post(url, json=payload, headers=self.headers)
    # ...
```

## 🚀 Vantagens do Baileys (via Evolution)

✅ **Multi-Device** nativo  
✅ **API REST pronta** (Evolution)  
✅ **Leve** - não usa Chrome/Puppeteer  
✅ **Estável** - comunidade gigante  
✅ **Docker** configurado  
✅ **Rotas prontas**: send-message, groups, status, etc  

## 📱 Como Reconectar

### Opção 1: Via Script (Recomendado)

```bash
./reconectar-whatsapp-evolution.sh
```

O script:
1. Deleta instância antiga
2. Cria nova instância Baileys
3. Gera QR Code
4. Mostra instruções

### Opção 2: Manual via cURL

```bash
# 1. Deletar instância antiga
curl -X DELETE 'http://82.25.92.217:21465/instance/delete/debrief' \
  -H 'apikey: debrief-wpp-58a2b7dda7da9474958e2a853062d5d5'

# 2. Criar nova instância com Baileys
curl -X POST 'http://82.25.92.217:21465/instance/create' \
  -H 'apikey: debrief-wpp-58a2b7dda7da9474958e2a853062d5d5' \
  -H 'Content-Type: application/json' \
  -d '{
    "instanceName": "debrief",
    "integration": "WHATSAPP-BAILEYS",
    "qrcode": true
  }'

# 3. Pegar QR Code (retorna base64)
# O QR Code vem no campo: response.qrcode.base64

# 4. Verificar status
curl -s 'http://82.25.92.217:21465/instance/connectionState/debrief' \
  -H 'apikey: debrief-wpp-58a2b7dda7da9474958e2a853062d5d5'
```

### Opção 3: Interface Web (Mais Fácil!)

Se o Evolution API tiver interface web habilitada:

```
http://82.25.92.217:21465/manager
```

## 🔍 Verificar Conexão

```bash
# Status da conexão
ssh root@82.25.92.217 "curl -s 'http://localhost:21465/instance/connectionState/debrief' \
  -H 'apikey: debrief-wpp-58a2b7dda7da9474958e2a853062d5d5'"

# Resposta esperada quando CONECTADO:
{
    "instance": {
        "instanceName": "debrief",
        "state": "open"  // ✅ CONECTADO!
    }
}

# Resposta atual (NÃO conectado):
{
    "instance": {
        "instanceName": "debrief",
        "state": "connecting"  // ⏳ Aguardando QR Code
    }
}
```

## 📋 Configuração do Backend

### Arquivo `.env` do Backend

```bash
# WhatsApp API (wpapi) - Nova implementação
WHATSAPP_API_URL=http://82.25.92.217:3001
WHATSAPP_API_KEY=HUxJYioH28+/q45I46lAw5eCOGrHeeFpNPmfWVc/0Ck=
```

⚠️ **NOTA**: A porta está configurada como **3001** no backend, mas o Evolution está rodando na porta **21465**!

### 🔧 Correção Necessária

```bash
ssh root@82.25.92.217 "cd /var/www/debrief/backend && \
  sed -i 's/WHATSAPP_API_URL=http:\/\/82.25.92.217:3001/WHATSAPP_API_URL=http:\/\/localhost:21465/g' .env"
```

Ou crie um proxy/redirect da porta 3001 para 21465.

## 🧪 Testar Envio de Mensagem

Após conectar o WhatsApp:

```bash
# Teste simples
curl -X POST 'http://82.25.92.217:21465/send-message' \
  -H 'apikey: debrief-wpp-58a2b7dda7da9474958e2a853062d5d5' \
  -H 'Content-Type: application/json' \
  -d '{
    "chatId": "5511999999999@c.us",
    "message": "🎉 DeBrief conectado via Baileys!"
  }'
```

## 📝 Logs

```bash
# Ver logs do Evolution/Baileys
ssh root@82.25.92.217 "docker logs wppconnect-server --tail 100 -f"

# Ver status do container
ssh root@82.25.92.217 "docker ps | grep wppconnect"
```

## ❓ Por que "device_removed"?

Os logs mostraram:

```json
{
  "level": 50,
  "node": {
    "tag": "stream:error",
    "attrs": {"code": "401"},
    "content": [{"tag": "conflict", "attrs": {"type": "device_removed"}}]
  },
  "msg": "stream errored out"
}
```

**Causa**: Alguém desconectou o WhatsApp Web pelo celular em "Aparelhos conectados".

**Solução**: Reconectar escaneando novo QR Code.

## 🎯 Próximos Passos

1. ✅ **Confirmar que Baileys está rodando** - FEITO!
2. 🔄 **Escanear QR Code** - PENDENTE
3. 🔧 **Corrigir porta no backend** (.env: 3001 → 21465)
4. 🧪 **Testar envio de mensagem**
5. ✨ **Configurar webhooks** (opcional)

## 💡 Dica Pro

O Evolution API permite múltiplas instâncias Baileys simultâneas!

```bash
# Criar instância para cada cliente
curl -X POST 'http://localhost:21465/instance/create' \
  -d '{"instanceName": "cliente1", "integration": "WHATSAPP-BAILEYS"}'
  
curl -X POST 'http://localhost:21465/instance/create' \
  -d '{"instanceName": "cliente2", "integration": "WHATSAPP-BAILEYS"}'
```

Cada cliente pode ter seu próprio WhatsApp conectado! 🎉

## 📚 Documentação Evolution API

- GitHub: https://github.com/EvolutionAPI/evolution-api
- Docs v1.x: https://doc.evolution-api.com/v1/

---

**Atualizado em**: 24/11/2025 19:02  
**Status**: Evolution funcionando, aguardando conexão WhatsApp

