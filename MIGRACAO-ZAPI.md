# 🔄 Migração WhatsApp: Evolution API → Z-API

## 📋 Situação Atual

**Data:** 24/11/2025

### ❌ Problema Identificado
- **Número WhatsApp bloqueado:** 55 85 91042626
- **Motivo:** Bloqueio pelo WhatsApp Business (uso comercial sem autorização)
- **Serviço anterior:** Evolution API v1.8.5 com Baileys (wppconnect-server)
- **Status:** Container wppconnect-server **REMOVIDO**

## ✅ Solução: Migração para Z-API

### Vantagens do Z-API
- ✅ Número dedicado e homologado
- ✅ Infraestrutura gerenciada (sem containers locais)
- ✅ API REST simples e confiável
- ✅ Suporte oficial do WhatsApp Business
- ✅ Menor risco de bloqueio

## 🔧 Passos Realizados

### 1. Remoção do WPPConnect/Evolution API
```bash
# Container removido
docker stop wppconnect-server
docker rm wppconnect-server

# Status: ✅ Desinstalado
```

### 2. Preparação do Backend

O código já está preparado para receber nova API. Precisaremos apenas:
- Atualizar `WHATSAPP_API_URL` (URL do Z-API)
- Atualizar `WHATSAPP_API_KEY` (Token Z-API)
- Ajustar o `WhatsAppService` para o formato da Z-API

## 📝 Aguardando Informações do Z-API

Por favor, forneça as seguintes informações do Z-API:

### Credenciais Necessárias

```env
# 1. URL da Instância Z-API
WHATSAPP_API_URL=https://api.z-api.io/instances/XXXXXXXX

# 2. Token de Autenticação
WHATSAPP_API_KEY=seu_token_aqui

# 3. Client Token (se necessário)
WHATSAPP_CLIENT_TOKEN=seu_client_token_aqui

# 4. Número WhatsApp (novo número não bloqueado)
WHATSAPP_NUMERO_REMETENTE=5585XXXXXXXXX
```

### Informações do Z-API

Precisamos saber:

1. **URL da Instância**
   - Exemplo: `https://api.z-api.io/instances/3C4F5G6H7I8J`
   
2. **Token de Autenticação**
   - Encontrado no painel Z-API
   
3. **Client Token** (opcional)
   - Alguns planos requerem

4. **ID da Instância**
   - Exemplo: `3C4F5G6H7I8J`

5. **Número WhatsApp Novo**
   - Não bloqueado
   - Formato: 5585XXXXXXXXX

6. **Documentação da API**
   - Endpoint para enviar mensagens
   - Endpoint para verificar status
   - Formato do payload

## 🔄 Próximos Passos (Após Receber Credenciais)

### 1. Atualizar Configurações
```python
# backend/app/core/config.py
class Settings(BaseSettings):
    # Z-API Configuration
    WHATSAPP_API_URL: str = "URL_FORNECIDA"
    WHATSAPP_API_KEY: str = "TOKEN_FORNECIDO"
    WHATSAPP_INSTANCE_ID: str = "ID_FORNECIDO"
```

### 2. Adaptar WhatsAppService
```python
# backend/app/services/whatsapp.py
class WhatsAppService:
    def __init__(self):
        self.base_url = settings.WHATSAPP_API_URL
        self.token = settings.WHATSAPP_API_KEY
        self.instance_id = settings.WHATSAPP_INSTANCE_ID
        
    def enviar_mensagem_individual(self, numero: str, mensagem: str) -> bool:
        """
        Adaptar para formato Z-API:
        POST /send-text
        {
            "phone": "5585991234567",
            "message": "Texto da mensagem"
        }
        """
        # Código a ser adaptado com base na doc Z-API
```

### 3. Testar Integração
- Verificar conexão
- Enviar mensagem de teste
- Validar recebimento

### 4. Atualizar Frontend
- Trocar número exibido
- Atualizar instruções para usuários

## 📊 Comparação de APIs

| Recurso | Evolution API (Antigo) | Z-API (Novo) |
|---------|------------------------|--------------|
| Hospedagem | Local (Docker) | Cloud (Gerenciada) |
| Número | Próprio (55 85 91042626) | Novo número |
| Status | ❌ Bloqueado | ✅ Ativo |
| Custo | Grátis | Pago (mais confiável) |
| Risco Bloqueio | Alto | Baixo |
| Suporte | Comunidade | Oficial |

## 🎯 Status Atual

- ✅ Evolution API desinstalado
- ✅ Documentação criada
- ⏳ **Aguardando credenciais Z-API**
- ⏳ Adaptação do código
- ⏳ Testes de integração
- ⏳ Deploy em produção

---

**Próximo Passo:** Fornecer credenciais e documentação da Z-API para prosseguir com a migração.

## 📞 Informações de Contato

Após receber as credenciais, a migração será concluída em aproximadamente:
- ⏱️ **15-30 minutos** (adaptação do código)
- ⏱️ **15 minutos** (testes)
- ⏱️ **10 minutos** (deploy)
- **Total:** ~1 hora

Aguardando suas instruções! 🚀

