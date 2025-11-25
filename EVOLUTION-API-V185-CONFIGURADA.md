# 🎯 Evolution API v1.8.5 - Configuração DeBrief

## ✅ Status: INSTALADA E AGUARDANDO CONEXÃO

---

## 📡 Informações da API

### Servidor
- **URL Base:** `http://82.25.92.217:21465`
- **Versão:** Evolution API v1.8.5
- **Porta:** 21465
- **Status:** 🟢 Online
- **Banco de Dados:** Desabilitado (armazenamento local em arquivos)

### Autenticação Global
- **API Key:** `debrief-wpp-58a2b7dda7da9474958e2a853062d5d5`
- **Header:** `apikey: debrief-wpp-58a2b7dda7da9474958e2a853062d5d5`

---

## 📱 Instância WhatsApp Criada

### Informações da Instância "debrief"
- **Nome:** `debrief`
- **Instance ID:** `ce3c707c-103c-4244-804a-6edfb2fcb128`
- **API Key Instância:** `B6CD7203-4819-4857-8107-FCD6C2F4EBC5`
- **Status Atual:** `connecting` (aguardando QR Code)

### QR Code para Conexão
```
2@bqhuipZ49gcbyIRvQJvfGWSnSlzNr1WgjE901KMrd/rMemy/5GiWm4ukAnDRtsSgJl8TQhSj5ac4qW9MO+rwj3yFad90RBwFZco=,N8whQVbKYvDwLvRVYcqf6vGZ3lo2nY6CvsTHzK0FST4=,3o7GVZto1bSQkiNd7TINJxkEx7mo5eCXRj0CvZKdGCk=,DMvbgOjfBVALZ0c7S2IpQX/NonAt6U8ULX+Fu0ducz0=
```

### 📱 Como Conectar:

1. **Desconectar sessões antigas:**
   - WhatsApp > Configurações > Aparelhos conectados
   - Desconectar qualquer sessão ativa da Evolution/Chrome

2. **Escanear QR Code:**
   - Acesse: `http://82.25.92.217:21465` no navegador
   - OU use o código acima para gerar novo QR
   - Escaneie com WhatsApp

3. **Verificar Conexão:**
```bash
curl -H "apikey: debrief-wpp-58a2b7dda7da9474958e2a853062d5d5" \
  http://82.25.92.217:21465/instance/connectionState/debrief
```

---

## 🌐 Endpoints Principais

### 1. Verificar Status da Instância
```bash
GET /instance/connectionState/{instanceName}
Header: apikey: debrief-wpp-58a2b7dda7da9474958e2a853062d5d5
```

**Exemplo:**
```bash
curl -H "apikey: debrief-wpp-58a2b7dda7da9474958e2a853062d5d5" \
  http://82.25.92.217:21465/instance/connectionState/debrief
```

**Resposta:**
```json
{
  "instance": {
    "instanceName": "debrief",
    "state": "open"  // open = conectado
  }
}
```

---

### 2. Listar Todas as Instâncias
```bash
GET /instance/fetchInstances
Header: apikey: debrief-wpp-58a2b7dda7da9474958e2a853062d5d5
```

---

### 3. Enviar Mensagem de Texto ⭐
```bash
POST /message/sendText/{instanceName}
Header: apikey: debrief-wpp-58a2b7dda7da9474958e2a853062d5d5
Content-Type: application/json

Body:
{
  "number": "5511999999999",  // ou "120363123456789@g.us" para grupo
  "textMessage": {
    "text": "Sua mensagem aqui"
  }
}
```

**Exemplo curl:**
```bash
curl -X POST http://82.25.92.217:21465/message/sendText/debrief \
  -H "apikey: debrief-wpp-58a2b7dda7da9474958e2a853062d5d5" \
  -H "Content-Type: application/json" \
  -d '{
    "number": "5511999999999",
    "textMessage": {
      "text": "🔔 NOVA DEMANDA\n\nTítulo: Teste\nPrioridade: Alta"
    }
  }'
```

---

### 4. Listar Todos os Chats
```bash
GET /chat/findChats/{instanceName}
Header: apikey: debrief-wpp-58a2b7dda7da9474958e2a853062d5d5
```

---

### 5. Obter Novo QR Code
```bash
GET /instance/connect/{instanceName}
Header: apikey: debrief-wpp-58a2b7dda7da9474958e2a853062d5d5
```

---

## 🔧 Integração com DeBrief

### 1. Atualizar Variáveis de Ambiente

No arquivo `/var/www/debrief/backend/.env`, adicionar/atualizar:

```env
# Evolution API v1.8.5
EVOLUTION_API_URL=http://82.25.92.217:21465
EVOLUTION_API_KEY=debrief-wpp-58a2b7dda7da9474958e2a853062d5d5
EVOLUTION_INSTANCE_NAME=debrief
```

### 2. Atualizar WhatsAppService (Python)

```python
import requests
from typing import Optional
import logging

logger = logging.getLogger(__name__)

class WhatsAppService:
    def __init__(self):
        self.base_url = "http://82.25.92.217:21465"
        self.api_key = "debrief-wpp-58a2b7dda7da9474958e2a853062d5d5"
        self.instance_name = "debrief"
        
        self.headers = {
            "apikey": self.api_key,
            "Content-Type": "application/json"
        }
    
    def enviar_mensagem(self, numero: str, mensagem: str) -> bool:
        """
        Envia mensagem via Evolution API
        
        Args:
            numero: Número WhatsApp (5511999999999) ou ID do grupo
            mensagem: Texto da mensagem
        
        Returns:
            True se enviado com sucesso
        """
        url = f"{self.base_url}/message/sendText/{self.instance_name}"
        
        payload = {
            "number": numero,
            "textMessage": {
                "text": mensagem
            }
        }
        
        try:
            logger.info(f"Enviando mensagem WhatsApp para {numero}")
            
            response = requests.post(
                url,
                headers=self.headers,
                json=payload,
                timeout=30
            )
            
            if response.status_code == 200 or response.status_code == 201:
                result = response.json()
                logger.info(f"Mensagem enviada: {result}")
                return True
            else:
                logger.error(f"Erro {response.status_code}: {response.text}")
                return False
                
        except Exception as e:
            logger.error(f"Exceção ao enviar WhatsApp: {e}")
            return False
    
    def verificar_conexao(self) -> bool:
        """Verifica se instância está conectada"""
        url = f"{self.base_url}/instance/connectionState/{self.instance_name}"
        
        try:
            response = requests.get(url, headers=self.headers, timeout=10)
            if response.status_code == 200:
                data = response.json()
                state = data.get("instance", {}).get("state")
                return state == "open"
        except:
            return False
        
        return False
    
    def listar_chats(self) -> list:
        """Lista todos os chats"""
        url = f"{self.base_url}/chat/findChats/{self.instance_name}"
        
        try:
            response = requests.get(url, headers=self.headers, timeout=10)
            if response.status_code == 200:
                return response.json()
        except Exception as e:
            logger.error(f"Erro ao listar chats: {e}")
            return []
        
        return []
```

### 3. Exemplo de Uso no DeBrief

```python
from app.services.whatsapp import WhatsAppService

# Enviar notificação de nova demanda
whatsapp = WhatsAppService()

if whatsapp.verificar_conexao():
    mensagem = f"""
🔔 NOVA DEMANDA RECEBIDA

📋 *Título:* {demanda.nome}
👤 *Cliente:* {demanda.cliente.nome}
🏢 *Secretaria:* {demanda.secretaria.nome}
⚠️ *Prioridade:* {demanda.prioridade.nome}
📅 *Prazo:* {demanda.prazo_final.strftime('%d/%m/%Y')}

🔗 Ver no Trello: {demanda.trello_card_url}
"""
    
    # Para grupo: usar ID do grupo (obter com listar_chats())
    # Para número individual: usar apenas o número
    resultado = whatsapp.enviar_mensagem("5511999999999", mensagem)
    
    if resultado:
        print("✅ Notificação enviada com sucesso!")
    else:
        print("❌ Falha ao enviar notificação")
else:
    print("⚠️ WhatsApp não conectado")
```

---

## 📝 Formato de Números

### Para Números Individuais:
```
5511999999999  (código do país + DDD + número)
```

### Para Grupos:
```
120363123456789012@g.us  (obter via listar_chats)
```

**Como obter ID do grupo:**
```python
whatsapp = WhatsAppService()
chats = whatsapp.listar_chats()

for chat in chats:
    if chat.get("name") == "Nome do Grupo":
        group_id = chat.get("id")
        print(f"ID do Grupo: {group_id}")
```

---

## 🔍 Comandos Úteis

### Verificar se API está rodando
```bash
curl http://82.25.92.217:21465
```

### Ver logs do container
```bash
ssh root@82.25.92.217
docker logs wppconnect-server --tail 50
```

### Verificar status da instância
```bash
curl -H "apikey: debrief-wpp-58a2b7dda7da9474958e2a853062d5d5" \
  http://82.25.92.217:21465/instance/connectionState/debrief
```

### Listar todas as instâncias
```bash
curl -H "apikey: debrief-wpp-58a2b7dda7da9474958e2a853062d5d5" \
  http://82.25.92.217:21465/instance/fetchInstances
```

### Reiniciar Evolution API
```bash
ssh root@82.25.92.217
cd /root/wppconnect
docker-compose restart
```

---

## ⚠️ Importante

1. **WhatsApp Business:** Se for usar WhatsApp Business, desconecte do app antes
2. **Apenas 1 Conexão:** WhatsApp permite apenas 1 conexão ativa por vez
3. **QR Code Expira:** Se não escanear em alguns segundos, precisa gerar novo
4. **Persistência:** Com banco desabilitado, sessão será mantida em arquivos locais

---

## 🎯 Próximos Passos

1. ✅ **ESCANEAR QR CODE** - Conectar WhatsApp
2. ⏳ Verificar conexão estabelecida
3. ⏳ Listar chats e obter ID do grupo
4. ⏳ Atualizar backend do DeBrief
5. ⏳ Testar envio de notificação

---

**Criado em:** 24/11/2025  
**Versão:** Evolution API v1.8.5  
**Status:** ⏳ Aguardando conexão WhatsApp

