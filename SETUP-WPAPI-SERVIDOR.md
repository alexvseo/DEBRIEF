# 🎯 WPapi - API WhatsApp Configurada no Servidor

## ✅ Status: INSTALADA E FUNCIONANDO

A API WhatsApp está rodando no servidor e pronta para uso.

---

## 📡 Informações da API

### Conexão
- **URL Interna:** `http://localhost:3001`
- **Porta:** 3001
- **API Key:** `HUxJYioH28+/q45I46lAw5eCOGrHeeFpNPmfWVc/0Ck=`
- **Status:** Online (gerenciado pelo PM2)

### Localização no Servidor
```bash
Diretório: /root/wpapi
Processo: PM2 (auto-start habilitado)
Logs: pm2 logs wpapi
```

---

## 🔐 Autenticação

Todas as requisições (exceto `/status`, `/qr` e `/docs`) requerem a API Key no header:

```bash
X-API-Key: HUxJYioH28+/q45I46lAw5eCOGrHeeFpNPmfWVc/0Ck=
```

Ou como parâmetro na URL:
```
?apikey=HUxJYioH28+/q45I46lAw5eCOGrHeeFpNPmfWVc/0Ck=
```

---

## 📱 Como Conectar o WhatsApp

### 1. Obter o QR Code

**Via Terminal (no servidor):**
```bash
ssh root@82.25.92.217
pm2 logs wpapi --lines 50
```

**Via API (qualquer lugar):**
```bash
curl http://82.25.92.217:3001/qr
```

### 2. Escanear com WhatsApp

1. Abra o WhatsApp no seu celular
2. Vá em **Configurações > Aparelhos conectados**
3. Toque em **"Conectar um aparelho"**
4. Escaneie o QR Code exibido nos logs ou retornado pela API

### 3. Verificar Conexão

```bash
curl http://82.25.92.217:3001/status
```

**Resposta quando conectado:**
```json
{
  "connected": true,
  "qrcode": null,
  "timestamp": "2025-11-24T21:30:00.000Z"
}
```

---

## 🌐 Endpoints Disponíveis

### 1. Status da Conexão
```bash
GET /status
```

**Exemplo:**
```bash
curl http://82.25.92.217:3001/status
```

---

### 2. Obter QR Code
```bash
GET /qr
```

**Exemplo:**
```bash
curl http://82.25.92.217:3001/qr
```

---

### 3. Enviar Mensagem (PRINCIPAL) ⭐
```bash
POST /send-message
Headers: X-API-Key: HUxJYioH28+/q45I46lAw5eCOGrHeeFpNPmfWVc/0Ck=
Content-Type: application/json

Body:
{
  "chatId": "5511999999999@c.us",  // Para contato individual
  "message": "Olá! Sua mensagem aqui"
}
```

**Para Grupos:**
```json
{
  "chatId": "120363123456789012@g.us",
  "message": "Mensagem para o grupo"
}
```

**Exemplo curl:**
```bash
curl -X POST http://82.25.92.217:3001/send-message \
  -H "X-API-Key: HUxJYioH28+/q45I46lAw5eCOGrHeeFpNPmfWVc/0Ck=" \
  -H "Content-Type: application/json" \
  -d '{
    "chatId": "5511999999999@c.us",
    "message": "🔔 DEMANDA RECEBIDA\n\nTítulo: Nova demanda\nPrioridade: Alta"
  }'
```

**Resposta de sucesso:**
```json
{
  "success": true,
  "message": "Mensagem enviada com sucesso",
  "messageId": "3EB0123456789ABCDEF",
  "timestamp": "2025-11-24T21:30:00.000Z",
  "to": "5511999999999@c.us"
}
```

---

### 4. Listar Chats
```bash
GET /chats
Headers: X-API-Key: HUxJYioH28+/q45I46lAw5eCOGrHeeFpNPmfWVc/0Ck=
```

**Exemplo:**
```bash
curl -H "X-API-Key: HUxJYioH28+/q45I46lAw5eCOGrHeeFpNPmfWVc/0Ck=" \
  http://82.25.92.217:3001/chats
```

**Resposta:**
```json
{
  "total": 150,
  "groups": [
    {
      "id": "120363123456789012@g.us",
      "name": "Equipe DeBrief",
      "isGroup": true,
      "participantsCount": 15,
      "lastMessage": "Última mensagem..."
    }
  ],
  "contacts": [
    {
      "id": "5511999999999@c.us",
      "name": "João Silva",
      "isGroup": false,
      "participantsCount": null,
      "lastMessage": "Oi!"
    }
  ],
  "timestamp": "2025-11-24T21:30:00.000Z"
}
```

---

### 5. Listar Apenas Grupos
```bash
GET /groups
Headers: X-API-Key: HUxJYioH28+/q45I46lAw5eCOGrHeeFpNPmfWVc/0Ck=
```

---

### 6. Testar Grupo Específico
```bash
POST /test-group
Headers: X-API-Key: HUxJYioH28+/q45I46lAw5eCOGrHeeFpNPmfWVc/0Ck=
Content-Type: application/json

Body:
{
  "groupId": "120363123456789012@g.us"
}
```

---

### 7. Documentação da API
```bash
GET /docs
```

**Exemplo:**
```bash
curl http://82.25.92.217:3001/docs
```

---

## 🔧 Gerenciamento do Serviço

### Ver Status
```bash
ssh root@82.25.92.217 "pm2 list"
```

### Ver Logs em Tempo Real
```bash
ssh root@82.25.92.217 "pm2 logs wpapi"
```

### Reiniciar
```bash
ssh root@82.25.92.217 "pm2 restart wpapi"
```

### Parar
```bash
ssh root@82.25.92.217 "pm2 stop wpapi"
```

### Iniciar
```bash
ssh root@82.25.92.217 "pm2 start wpapi"
```

---

## 🚀 Integração com DeBrief

### 1. Adicionar Variável de Ambiente no Backend

Edite o arquivo `/var/www/debrief/backend/.env`:

```env
# WhatsApp API
WHATSAPP_API_URL=http://82.25.92.217:3001
WHATSAPP_API_KEY=HUxJYioH28+/q45I46lAw5eCOGrHeeFpNPmfWVc/0Ck=
```

### 2. Atualizar WhatsappService

No arquivo `backend/app/services/whatsapp.py`, atualize para usar a nova API:

```python
import os
import requests
from typing import Optional

class WhatsappService:
    def __init__(self):
        self.api_url = os.getenv("WHATSAPP_API_URL")
        self.api_key = os.getenv("WHATSAPP_API_KEY")
    
    def enviar_mensagem(self, chat_id: str, mensagem: str) -> dict:
        """
        Envia mensagem via WhatsApp
        
        Args:
            chat_id: ID do chat (ex: 5511999999999@c.us ou 120363123456789012@g.us)
            mensagem: Texto da mensagem
        
        Returns:
            dict com resultado do envio
        """
        try:
            response = requests.post(
                f"{self.api_url}/send-message",
                headers={
                    "X-API-Key": self.api_key,
                    "Content-Type": "application/json"
                },
                json={
                    "chatId": chat_id,
                    "message": mensagem
                },
                timeout=30
            )
            response.raise_for_status()
            return response.json()
        except Exception as e:
            print(f"Erro ao enviar mensagem WhatsApp: {e}")
            return {"success": False, "error": str(e)}
    
    def verificar_conexao(self) -> bool:
        """Verifica se o WhatsApp está conectado"""
        try:
            response = requests.get(f"{self.api_url}/status", timeout=10)
            data = response.json()
            return data.get("connected", False)
        except:
            return False
```

### 3. Exemplo de Uso no Backend

```python
from app.services.whatsapp import WhatsappService

# Enviar notificação de nova demanda
whatsapp = WhatsappService()

if whatsapp.verificar_conexao():
    mensagem = f"""
🔔 NOVA DEMANDA RECEBIDA

📋 *Título:* {demanda.nome}
👤 *Cliente:* {demanda.cliente.nome}
🏢 *Secretaria:* {demanda.secretaria.nome}
⚠️ *Prioridade:* {demanda.prioridade.nome}

🔗 Ver detalhes: https://debrief.interce.com.br/demanda/{demanda.id}
"""
    
    # Enviar para grupo (obter ID do grupo em /groups)
    resultado = whatsapp.enviar_mensagem(
        "120363123456789012@g.us",  # ID do grupo
        mensagem
    )
    
    print(f"WhatsApp enviado: {resultado}")
```

---

## 📝 Formato do chatId

### Para Contatos Individuais:
```
{número_com_ddd}@c.us
Exemplo: 5511999999999@c.us
```

### Para Grupos:
```
{id_do_grupo}@g.us
Exemplo: 120363123456789012@g.us
```

**Como obter ID do grupo:**
1. Enviar mensagem no grupo via WhatsApp Web
2. Chamar `/groups` na API
3. Encontrar o grupo pelo nome

---

## ⚠️ Limitações

- ✅ **Funciona:** 1 número WhatsApp conectado
- ❌ **Não suporta:** Múltiplas instâncias
- ❌ **Não tem:** Interface web
- ⚠️ **Importante:** Se desconectar, precisa escanear QR Code novamente

---

## 🔍 Troubleshooting

### WhatsApp desconectou
```bash
ssh root@82.25.92.217
pm2 logs wpapi --lines 50
# Escanear novo QR Code que aparecerá
```

### API não responde
```bash
ssh root@82.25.92.217
pm2 restart wpapi
pm2 logs wpapi
```

### Ver status detalhado
```bash
ssh root@82.25.92.217
pm2 show wpapi
```

---

## 📞 Próximos Passos

1. ✅ **CONECTAR WHATSAPP:** Escanear o QR Code agora
2. ✅ **TESTAR API:** Enviar uma mensagem teste
3. ⏳ **OBTER ID DO GRUPO:** Listar grupos e pegar o ID
4. ⏳ **INTEGRAR NO BACKEND:** Adicionar notificações no DeBrief
5. ⏳ **AVALIAR EVOLUÇÃO FUTURA:** Se precisar de múltiplas instâncias

---

## 🎯 Resumo de Comandos Úteis

```bash
# Ver QR Code
ssh root@82.25.92.217 "pm2 logs wpapi --lines 50"

# Testar status
curl http://82.25.92.217:3001/status

# Listar grupos
curl -H "X-API-Key: HUxJYioH28+/q45I46lAw5eCOGrHeeFpNPmfWVc/0Ck=" \
  http://82.25.92.217:3001/groups

# Enviar mensagem teste
curl -X POST http://82.25.92.217:3001/send-message \
  -H "X-API-Key: HUxJYioH28+/q45I46lAw5eCOGrHeeFpNPmfWVc/0Ck=" \
  -H "Content-Type: application/json" \
  -d '{"chatId":"5511999999999@c.us","message":"Teste!"}'
```

---

**Criado em:** 24/11/2025
**Status:** ✅ Operacional
**Tecnologia:** whatsapp-web.js + Express + PM2

