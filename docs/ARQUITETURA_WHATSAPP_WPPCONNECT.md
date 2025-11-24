# Arquitetura WhatsApp - WPPConnect

## 🎯 Regra de Arquitetura

**TODOS os envios de mensagens WhatsApp do sistema DeBrief DEVEM ser feitos através do módulo WPPConnect.**

Não é permitido o uso de:
- ❌ Bibliotecas alternativas de WhatsApp
- ❌ APIs diferentes do WPPConnect
- ❌ Envio direto sem passar pelo `WhatsAppService`

## 📐 Arquitetura do Sistema

### Camadas de Comunicação

```
┌─────────────────────────────────────────────────────────────┐
│                    CAMADA DE APLICAÇÃO                       │
│                                                              │
│  • Endpoints FastAPI                                         │
│  • Services de Domínio (Demanda, Cliente, etc)              │
│  • Event Handlers                                            │
└────────────────────────┬─────────────────────────────────────┘
                         │
                         ▼
┌─────────────────────────────────────────────────────────────┐
│              CAMADA DE NOTIFICAÇÕES                          │
│                                                              │
│  NotificationWhatsAppService                                 │
│  ├─ Gerencia notificações individuais para usuários          │
│  ├─ Busca usuários que devem ser notificados                │
│  ├─ Seleciona templates baseado no tipo de evento           │
│  ├─ Renderiza mensagens com dados dinâmicos                 │
│  └─ Registra logs de todas notificações                     │
│                                                              │
│  Métodos Principais:                                         │
│  • notificar_demanda_criada(demanda)                         │
│  • notificar_demanda_atualizada(demanda)                     │
│  • notificar_demanda_concluida(demanda)                      │
│  • notificar_demanda_cancelada(demanda)                      │
└────────────────────────┬─────────────────────────────────────┘
                         │
                         ▼
┌─────────────────────────────────────────────────────────────┐
│           CAMADA DE COMUNICAÇÃO WHATSAPP                     │
│                                                              │
│  WhatsAppService                                             │
│  ├─ Comunicação direta com API WPPConnect                   │
│  ├─ Gerencia autenticação (token)                           │
│  ├─ Gerencia configuração de instância                      │
│  └─ Trata erros e timeouts                                  │
│                                                              │
│  Métodos Principais:                                         │
│  • enviar_mensagem(group_id, mensagem)                       │
│  • enviar_mensagem_individual(numero, mensagem)              │
│  • verificar_status_instancia()                              │
│                                                              │
│  Dependências:                                               │
│  • requests (HTTP client)                                    │
│  • settings (WPP_URL, WPP_INSTANCE, WPP_TOKEN)              │
└────────────────────────┬─────────────────────────────────────┘
                         │
                         ▼
┌─────────────────────────────────────────────────────────────┐
│                    API WPPCONNECT                            │
│                                                              │
│  Endpoints Utilizados:                                       │
│  • POST /api/{instance}/send-text                            │
│  • GET  /api/{instance}/status                               │
│                                                              │
│  Autenticação:                                               │
│  • Bearer Token no header Authorization                      │
│                                                              │
│  Formato de Requisição (send-text):                         │
│  {                                                           │
│    "phone": "5511999999999",                                 │
│    "message": "Texto da mensagem",                           │
│    "isGroup": false                                          │
│  }                                                           │
└─────────────────────────────────────────────────────────────┘
```

## 🔧 Componentes

### 1. WhatsAppService

**Localização:** `backend/app/services/whatsapp.py`

**Responsabilidades:**
- Comunicação HTTP com API WPPConnect
- Gerenciamento de autenticação
- Formatação de payloads
- Tratamento de erros e timeouts
- Logging de operações

**Métodos:**

```python
# Enviar mensagem para grupo
async def enviar_mensagem(
    self,
    group_id: str,
    mensagem: str,
    mencoes: Optional[list] = None
) -> bool

# Enviar mensagem individual
def enviar_mensagem_individual(
    self,
    numero: str,
    mensagem: str
) -> bool

# Verificar status da instância
async def verificar_status_instancia(self) -> dict

# Métodos legados (para grupos)
async def enviar_nova_demanda(demanda, db) -> bool
async def enviar_atualizacao_status(demanda, db, status_antigo) -> bool
async def enviar_lembrete_prazo(demanda, db, dias_faltando) -> bool
```

**Configuração:**
```python
# Variáveis de ambiente necessárias
WPP_URL=https://seu-servidor-wppconnect.com
WPP_INSTANCE=nome-da-instancia
WPP_TOKEN=seu-token-aqui
```

### 2. NotificationWhatsAppService

**Localização:** `backend/app/services/notification_whatsapp.py`

**Responsabilidades:**
- Orquestração de notificações individuais
- Seleção de usuários para notificar
- Busca e renderização de templates
- Registro de logs de notificações
- Estatísticas de envio

**Fluxo de Notificação:**

```python
# 1. Verificar configuração ativa
config = ConfiguracaoWhatsApp.get_ativa(db)

# 2. Buscar template para o evento
template = TemplateMensagem.get_by_tipo_evento(db, "demanda_criada")

# 3. Buscar usuários para notificar
usuarios = db.query(User).filter(
    User.cliente_id == demanda.cliente_id,
    User.whatsapp != None,
    User.receber_notificacoes == True,
    User.ativo == True
).all()

# 4. Extrair dados da demanda
dados = {
    "demanda_titulo": demanda.nome,
    "cliente_nome": demanda.cliente.nome,
    "prioridade": demanda.prioridade.nome,
    # ... outros campos
}

# 5. Renderizar mensagem
mensagem = template.renderizar(dados)

# 6. Enviar para cada usuário
for usuario in usuarios:
    whatsapp_service.enviar_mensagem_individual(
        numero=usuario.whatsapp,
        mensagem=mensagem
    )
    
    # 7. Registrar log
    NotificationLog.create(...)
```

### 3. ConfiguracaoWhatsApp (Model)

**Localização:** `backend/app/models/configuracao_whatsapp.py`

**Campos:**
- `numero_remetente`: Número WhatsApp Business
- `instancia_wpp`: Nome da instância WPPConnect
- `token_wpp`: Token de autenticação
- `ativo`: Flag de configuração ativa

**Regra:** Apenas UMA configuração pode estar ativa por vez.

### 4. TemplateMensagem (Model)

**Localização:** `backend/app/models/template_mensagem.py`

**Campos:**
- `nome`: Nome do template
- `tipo_evento`: Tipo de evento (demanda_criada, demanda_atualizada, etc)
- `mensagem`: Texto com variáveis `{{nome_variavel}}`
- `ativo`: Flag de template ativo

**Variáveis Disponíveis:**
- `{{demanda_titulo}}`
- `{{demanda_descricao}}`
- `{{cliente_nome}}`
- `{{secretaria_nome}}`
- `{{tipo_demanda}}`
- `{{prioridade}}`
- `{{prazo_final}}`
- `{{usuario_responsavel}}`
- `{{usuario_nome}}`
- `{{trello_card_url}}`
- Entre outras...

### 5. NotificationLog (Model)

**Localização:** `backend/app/models/notification_log.py`

**Campos:**
- `demanda_id`: ID da demanda
- `usuario_id`: ID do usuário destinatário
- `tipo`: Tipo de notificação (WhatsApp, Email, etc)
- `destinatario`: Número/email do destinatário
- `mensagem`: Conteúdo enviado
- `status`: Status do envio (Enviado, Erro, Pendente)
- `erro_mensagem`: Descrição do erro (se houver)
- `enviado_em`: Data/hora do envio

## 📝 Como Adicionar Novos Tipos de Notificação

### 1. Criar Template no Banco

```sql
INSERT INTO templates_mensagens (nome, tipo_evento, mensagem, ativo)
VALUES (
    'Demanda Aprovada',
    'demanda_aprovada',
    '✅ *Demanda Aprovada*

📋 *Demanda:* {{demanda_titulo}}
🏢 *Cliente:* {{cliente_nome}}
👤 *Aprovador:* {{aprovador_nome}}

_Sistema DeBrief_',
    true
);
```

### 2. Adicionar Método no NotificationWhatsAppService

```python
def notificar_demanda_aprovada(self, demanda: Demanda) -> dict:
    """
    Notificar sobre aprovação de demanda
    
    Args:
        demanda: Demanda aprovada
        
    Returns:
        Estatísticas de envio
    """
    return self.notificar_evento(demanda, "demanda_aprovada")
```

### 3. Chamar no Endpoint/Service Apropriado

```python
# Em app/services/demanda.py
def aprovar_demanda(demanda_id: str, db: Session):
    demanda = db.query(Demanda).get(demanda_id)
    demanda.status = StatusDemanda.APROVADA
    db.commit()
    
    # Enviar notificação
    notification_service = NotificationWhatsAppService(db)
    notification_service.notificar_demanda_aprovada(demanda)
```

## 🔒 Boas Práticas

### 1. Sempre use o WhatsAppService
```python
# ✅ CORRETO
from app.services.whatsapp import WhatsAppService

whatsapp = WhatsAppService()
whatsapp.enviar_mensagem_individual("5511999999999", "Mensagem")

# ❌ ERRADO
import requests
requests.post("https://api-whatsapp.com/send", ...)  # Não fazer!
```

### 2. Use NotificationWhatsAppService para notificações de sistema
```python
# ✅ CORRETO - Para notificações de eventos
from app.services.notification_whatsapp import NotificationWhatsAppService

service = NotificationWhatsAppService(db)
service.notificar_demanda_criada(demanda)

# ✅ CORRETO - Para mensagens avulsas/admin
from app.services.whatsapp import WhatsAppService

whatsapp = WhatsAppService()
whatsapp.enviar_mensagem_individual("5511999999999", "Mensagem admin")
```

### 3. Sempre registre logs
```python
# O NotificationWhatsAppService já registra automaticamente
# Se usar WhatsAppService diretamente, registre manualmente:

sucesso = whatsapp.enviar_mensagem_individual(numero, mensagem)

log = NotificationLog(
    usuario_id=usuario.id,
    tipo=TipoNotificacao.WHATSAPP,
    destinatario=numero,
    mensagem=mensagem,
    status=StatusNotificacao.ENVIADO if sucesso else StatusNotificacao.ERRO
)
db.add(log)
db.commit()
```

### 4. Trate erros adequadamente
```python
try:
    service = NotificationWhatsAppService(db)
    resultado = service.notificar_demanda_criada(demanda)
    
    if resultado["falhas"] > 0:
        logger.warning(f"{resultado['falhas']} notificações falharam")
        
except Exception as e:
    logger.error(f"Erro ao enviar notificações: {e}")
    # Sistema deve continuar funcionando mesmo se WhatsApp falhar
```

## 🧪 Testes

### Testar Conexão WPPConnect
```python
# Endpoint: GET /api/v1/whatsapp/config/test
# Ou via código:

from app.services.whatsapp import WhatsAppService

whatsapp = WhatsAppService()
status = await whatsapp.verificar_status_instancia()
print(status)
```

### Testar Envio Individual
```python
# Endpoint: POST /api/v1/whatsapp/config/test
# Body:
{
    "numero_teste": "5511999999999",
    "mensagem": "Teste de conexão - DeBrief"
}
```

### Testar Notificação de Sistema
```python
from app.services.notification_whatsapp import NotificationWhatsAppService

service = NotificationWhatsAppService(db)
resultado = service.notificar_demanda_criada(demanda)

print(f"Enviados: {resultado['enviados']}")
print(f"Falhas: {resultado['falhas']}")
```

## 📊 Monitoramento

### Logs de Notificações
```sql
-- Ver últimas notificações enviadas
SELECT 
    nl.created_at,
    u.nome_completo as usuario,
    nl.destinatario,
    nl.status,
    nl.erro_mensagem
FROM notification_logs nl
JOIN users u ON nl.usuario_id = u.id
ORDER BY nl.created_at DESC
LIMIT 20;

-- Estatísticas de envio
SELECT 
    status,
    COUNT(*) as total
FROM notification_logs
WHERE created_at >= NOW() - INTERVAL '24 hours'
GROUP BY status;
```

### Verificar Configuração Ativa
```sql
SELECT 
    numero_remetente,
    instancia_wpp,
    ativo,
    updated_at
FROM configuracoes_whatsapp
WHERE ativo = true;
```

## 🚫 O Que NÃO Fazer

1. ❌ **Não instalar outras bibliotecas WhatsApp**
   ```bash
   # NÃO fazer:
   pip install pywhatkit
   pip install whatsapp-api
   ```

2. ❌ **Não fazer requests diretos à API**
   ```python
   # NÃO fazer:
   requests.post("https://api.whatsapp.com/...", ...)
   ```

3. ❌ **Não criar múltiplas configurações ativas**
   ```python
   # O sistema garante apenas uma ativa
   # Se tentar ativar outra, desativa a anterior automaticamente
   ```

4. ❌ **Não enviar mensagens sem registrar log**
   ```python
   # Sempre use NotificationWhatsAppService
   # ou registre log manualmente se usar WhatsAppService direto
   ```

## 🔄 Migração de Sistema Antigo

Se houver código antigo que use outros métodos:

```python
# ANTIGO (remover)
def enviar_whatsapp_legacy(numero, mensagem):
    # código antigo
    pass

# NOVO (usar)
from app.services.whatsapp import WhatsAppService

def enviar_whatsapp(numero, mensagem):
    whatsapp = WhatsAppService()
    return whatsapp.enviar_mensagem_individual(numero, mensagem)
```

## 📚 Referências

- **WPPConnect Docs:** https://wppconnect.io/
- **WPPConnect API:** https://github.com/wppconnect-team/wppconnect-server
- **Código Fonte:**
  - `backend/app/services/whatsapp.py`
  - `backend/app/services/notification_whatsapp.py`
  - `backend/app/models/configuracao_whatsapp.py`
  - `backend/app/models/template_mensagem.py`
  - `backend/app/models/notification_log.py`

---

**Última atualização:** 23/11/2025
**Autor:** DeBrief Team

