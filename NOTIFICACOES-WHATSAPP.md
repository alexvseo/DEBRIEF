# Sistema de Notificações via WhatsApp - DeBrief

## 📋 Visão Geral

O sistema DeBrief possui um sistema completo de notificações individuais via WhatsApp que notifica usuários sobre eventos importantes relacionados às demandas.

### ✅ Características Principais

1. **Notificações Individuais**: Apenas mensagens pessoa a pessoa (sem grupos)
2. **Segmentação por Cliente**: Usuários recebem apenas notificações do seu cliente
3. **Controle Total**: Usuários podem cadastrar WhatsApp e desabilitar notificações
4. **Masters recebem tudo**: Usuários Master são notificados sobre TODAS as demandas

---

## 🎯 Regras de Negócio

### Quem Recebe Notificações?

#### Usuários Comuns (tipo: cliente)
- ✅ Recebem notificações APENAS de demandas do **seu cliente**
- ✅ Exemplo: Usuário vinculado a "Russas" só recebe notificações de demandas de "Russas"

#### Usuários Master (tipo: master)
- ✅ Recebem notificações de **TODAS as demandas**
- ✅ Independente do cliente da demanda

### Requisitos para Receber Notificações

Para um usuário receber notificações, ele DEVE:

1. ✅ Estar **ativo** no sistema (`ativo = true`)
2. ✅ Ter **WhatsApp cadastrado** (`whatsapp != null` e `whatsapp != ""`)
3. ✅ Ter notificações **habilitadas** (`receber_notificacoes = true`)

---

## 🔔 Eventos que Disparam Notificações

### 1. Nova Demanda Criada
**Quando:** Uma nova demanda é criada no sistema

**Mensagem:**
```
🔔 Nova Demanda Criada!

📋 Demanda: [Nome da demanda]
🏢 Cliente: [Nome do cliente]
🏛️ Secretaria: [Nome da secretaria]
📌 Tipo: [Tipo da demanda]
🟢 Prioridade: [Prioridade]
📅 Prazo: [Data limite]

👤 Solicitante: [Nome completo do usuário]

🔗 Ver no Sistema: [URL do Trello]

_ID: [ID da demanda]_
```

### 2. Demanda Atualizada
**Quando:** Uma demanda é editada (nome, descrição, prazo, etc)

**Mensagem:**
```
🔄 Demanda Atualizada

📋 Demanda: [Nome da demanda]
🏢 Cliente: [Nome do cliente]
🏛️ Secretaria: [Nome da secretaria]
📊 Status: [Status atual]

🔗 Ver detalhes: [URL do Trello]

_ID: [ID da demanda]_
```

### 3. Status Alterado
**Quando:** O status da demanda muda (aberta → em andamento → concluída)

**Mensagens Especiais:**

**Em Desenvolvimento:**
```
💻 Demanda em Desenvolvimento!

📋 Demanda: [Nome da demanda]
🏢 Cliente: [Nome do cliente]

💻 Status: Aberta → Em Desenvolvimento

🔗 Ver no Sistema: [URL do Trello]
```

**Concluída:**
```
✅ Demanda Concluída!

📋 Demanda: [Nome da demanda]
🏢 Cliente: [Nome do cliente]

✅ Status: Em Andamento → Concluída

🔗 Ver no Sistema: [URL do Trello]
```

### 4. Demanda Excluída
**Quando:** Uma demanda é removida do sistema

**Mensagem:**
```
🗑️ Demanda Excluída

📋 Demanda: [Nome da demanda]
🏢 Cliente: [Nome do cliente]
🏛️ Secretaria: [Nome da secretaria]

⚠️ Esta demanda foi removida do sistema.

_ID: [ID da demanda]_
```

---

## 🛠️ Arquitetura Técnica

### Serviço de Notificações

**Arquivo:** `backend/app/services/notification.py`

**Classe Principal:** `NotificationService`

#### Métodos Principais:

```python
# Instanciar serviço
notification_service = NotificationService(db)

# Notificar nova demanda
enviados = notification_service.notificar_nova_demanda(demanda)

# Notificar atualização
enviados = notification_service.notificar_atualizacao_demanda(demanda, campos_alterados)

# Notificar mudança de status
enviados = notification_service.notificar_mudanca_status(demanda, status_antigo, status_novo)

# Notificar exclusão
enviados = notification_service.notificar_exclusao_demanda(demanda)
```

#### Método Interno de Segmentação:

```python
def _obter_usuarios_para_notificar(self, demanda: Demanda) -> List[User]:
    """
    Query que retorna:
    - Usuários ativos
    - Com WhatsApp cadastrado
    - Com notificações habilitadas
    - Que são Master OU do mesmo cliente da demanda
    """
    query = self.db.query(User).filter(
        User.ativo == True,
        User.whatsapp.isnot(None),
        User.whatsapp != "",
        User.receber_notificacoes == True
    )
    
    usuarios = query.filter(
        (User.tipo == "master") | (User.cliente_id == demanda.cliente_id)
    ).all()
    
    return usuarios
```

### Integração nos Endpoints

**Arquivo:** `backend/app/api/endpoints/demandas.py`

As notificações são disparadas automaticamente nos endpoints:

1. **POST /api/demandas** - Criar demanda
2. **PUT /api/demandas/{id}** - Atualizar demanda
3. **DELETE /api/demandas/{id}** - Excluir demanda

**Exemplo de integração:**
```python
# Após criar demanda
try:
    notification_service = NotificationService(db)
    enviados = notification_service.notificar_nova_demanda(nova_demanda)
    logger.info(f"Notificações WhatsApp enviadas: {enviados} usuários")
except Exception as e:
    logger.error(f"Erro ao enviar notificações: {e}")
    # Não falhar a operação se notificações falharem
```

### Logs de Notificações

Todas as notificações são registradas na tabela `notification_logs`:

**Campos:**
- `demanda_id` - ID da demanda relacionada
- `tipo` - Tipo de notificação (whatsapp)
- `status` - Status do envio (enviado/erro/pendente)
- `mensagem_erro` - Mensagem de erro se houver falha
- `tentativas` - Número de tentativas
- `dados_enviados` - JSON com dados do envio (usuário, evento, etc)
- `resposta` - JSON com resposta da API WhatsApp

---

## 👤 Gerenciamento de Configurações de Usuário

### Endpoints Disponíveis

#### 1. Ver Perfil Atual
```http
GET /api/usuarios/me
Authorization: Bearer {token}
```

**Resposta:**
```json
{
  "id": "uuid",
  "username": "joao.silva",
  "email": "joao@example.com",
  "nome_completo": "João Silva",
  "tipo": "cliente",
  "cliente_id": "cliente-uuid",
  "ativo": true,
  "whatsapp": "5585991042626",
  "receber_notificacoes": true,
  "created_at": "2024-01-01T00:00:00",
  "updated_at": "2024-01-01T00:00:00"
}
```

#### 2. Atualizar Configurações de Notificação
```http
PUT /api/usuarios/me/notificacoes
Authorization: Bearer {token}
Content-Type: application/json

{
  "whatsapp": "5585991042626",
  "receber_notificacoes": true
}
```

**Resposta:** Dados completos do usuário atualizado

**Exemplos de Uso:**

**Adicionar/Atualizar WhatsApp:**
```json
{
  "whatsapp": "5585991042626"
}
```

**Desabilitar Notificações:**
```json
{
  "receber_notificacoes": false
}
```

**Remover WhatsApp:**
```json
{
  "whatsapp": ""
}
```

**Atualizar Ambos:**
```json
{
  "whatsapp": "5585999887766",
  "receber_notificacoes": true
}
```

### Formato do Número WhatsApp

**Formato aceito:** Apenas dígitos, com código do país

**Exemplos válidos:**
- `5585991042626` (Brasil, Ceará)
- `5511999887766` (Brasil, São Paulo)
- `5521988776655` (Brasil, Rio de Janeiro)

**Validação:**
- Mínimo: 10 dígitos
- Máximo: 15 dígitos
- Apenas números (caracteres especiais são removidos automaticamente)

---

## 🧪 Como Testar

### 1. Configurar Usuário para Receber Notificações

**Via API (Endpoint de Configuração):**
```bash
curl -X PUT http://localhost:8000/api/usuarios/me/notificacoes \
  -H "Authorization: Bearer {seu-token}" \
  -H "Content-Type: application/json" \
  -d '{
    "whatsapp": "5585991042626",
    "receber_notificacoes": true
  }'
```

**Via Banco de Dados Direto:**
```sql
-- Atualizar usuário específico
UPDATE users 
SET whatsapp = '5585991042626', 
    receber_notificacoes = true 
WHERE email = 'seu.email@example.com';

-- Verificar configuração
SELECT id, username, email, whatsapp, receber_notificacoes, cliente_id, tipo 
FROM users 
WHERE email = 'seu.email@example.com';
```

### 2. Criar Demanda e Verificar Notificação

1. **Crie uma nova demanda** (via interface ou API)
2. **Verifique o log da aplicação** para confirmar envio:
   ```
   INFO: Notificações WhatsApp enviadas: 2 usuários
   INFO: Notificação enviada para João Silva (5585991042626)
   ```
3. **Verifique o WhatsApp** do número cadastrado

### 3. Verificar Logs de Notificação

**Via Banco de Dados:**
```sql
-- Ver últimas notificações enviadas
SELECT 
    nl.id,
    nl.tipo,
    nl.status,
    nl.created_at,
    d.nome as demanda_nome,
    nl.dados_enviados
FROM notification_logs nl
JOIN demandas d ON d.id = nl.demanda_id
ORDER BY nl.created_at DESC
LIMIT 20;

-- Contar notificações por status
SELECT 
    status,
    COUNT(*) as total
FROM notification_logs
WHERE tipo = 'whatsapp'
GROUP BY status;
```

### 4. Testar Segmentação por Cliente

**Cenário de Teste:**

1. **Criar 3 usuários:**
   - Usuário A: cliente_id = "russas", whatsapp configurado
   - Usuário B: cliente_id = "quixada", whatsapp configurado
   - Usuário C: tipo = "master", whatsapp configurado

2. **Criar demanda para cliente "Russas":**
   - ✅ Usuário A deve receber notificação (mesmo cliente)
   - ❌ Usuário B NÃO deve receber (cliente diferente)
   - ✅ Usuário C deve receber (é master)

3. **Verificar logs:**
   ```sql
   SELECT dados_enviados 
   FROM notification_logs 
   WHERE demanda_id = 'id-da-demanda-criada'
   ORDER BY created_at DESC;
   ```

---

## 📊 Monitoramento e Troubleshooting

### Verificar Status do WhatsApp

```bash
# Via script
./testar-envio-whatsapp.sh

# Ou diretamente na API
curl http://localhost:21465/instance/connectionState/debrief \
  -H "apikey: debrief-wpp-58a2b7dda7da9474958e2a853062d5d5"
```

### Logs da Aplicação

**Backend logs:**
```bash
# Filtrar logs de notificações
tail -f backend/logs/app.log | grep -i "notific"

# Ver erros de WhatsApp
tail -f backend/logs/app.log | grep -i "whatsapp"
```

### Problemas Comuns

#### 1. Notificações não sendo enviadas

**Checklist:**
- [ ] Usuário tem WhatsApp cadastrado?
- [ ] Campo `receber_notificacoes` está `true`?
- [ ] Usuário está ativo?
- [ ] Usuário pertence ao mesmo cliente da demanda (ou é master)?
- [ ] Evolution API está conectada?

**Query de diagnóstico:**
```sql
SELECT 
    id,
    username,
    email,
    tipo,
    cliente_id,
    whatsapp,
    receber_notificacoes,
    ativo
FROM users
WHERE id = 'usuario-id';
```

#### 2. Evolution API desconectada

**Reconectar:**
```bash
./reconectar-whatsapp-evolution.sh
```

#### 3. Número WhatsApp inválido

**Validação:**
- Deve ter 10-15 dígitos
- Deve incluir código do país
- Exemplo correto: `5585991042626`
- Exemplo incorreto: `85991042626` (sem código do país 55)

---

## 🔒 Segurança e Privacidade

### Dados Sensíveis

- **Números de WhatsApp** são armazenados no banco de dados
- **Mensagens** não são armazenadas (apenas logs estruturados)
- **API Key** do WhatsApp está protegida em variáveis de ambiente

### Controle de Acesso

- Usuários **podem ver/editar** apenas suas próprias configurações
- Masters **podem ver** configurações de todos os usuários
- **Não há endpoint público** de listagem de WhatsApps

### LGPD / Privacidade

- Usuários podem **desabilitar notificações** a qualquer momento
- Usuários podem **remover seu WhatsApp** do sistema
- Logs de notificação **não contém conteúdo de mensagens**

---

## 📝 Changelog

### Versão 1.0 - 24/11/2024

**Implementado:**
- ✅ Sistema de notificações individuais via WhatsApp
- ✅ Segmentação por cliente (usuários comuns) vs Master (recebe tudo)
- ✅ Notificações para: criar, atualizar, excluir, mudança de status
- ✅ Endpoints de configuração de usuário (`/me` e `/me/notificacoes`)
- ✅ Logs de notificações na tabela `notification_logs`
- ✅ Validação de número WhatsApp
- ✅ Controle de receber_notificacoes

**Pendente:**
- ⏳ Interface web para configurar WhatsApp no perfil do usuário
- ⏳ Notificações de lembrete de prazo (agendadas)
- ⏳ Relatórios de entrega de notificações

---

## 🚀 Próximos Passos (Frontend)

Para implementar a interface de configuração no frontend:

### 1. Criar página de Perfil do Usuário
**Arquivo:** `frontend/src/pages/Perfil.jsx`

Incluir:
- Formulário para editar WhatsApp
- Toggle para habilitar/desabilitar notificações
- Preview do número formatado
- Botão de teste de notificação

### 2. Adicionar chamadas à API
**Arquivo:** `frontend/src/services/api.js`

```javascript
// Obter perfil atual
export const getMe = async () => {
  return api.get('/usuarios/me');
};

// Atualizar configurações de notificação
export const updateNotificationSettings = async (settings) => {
  return api.put('/usuarios/me/notificacoes', settings);
};
```

### 3. Criar componente de configuração
**Componente:** `<ConfiguracaoNotificacoes />`

Com:
- Input para WhatsApp (com máscara)
- Checkbox para receber_notificacoes
- Feedback visual de sucesso/erro
- Validação de formato

---

## 📞 Suporte

Para problemas ou dúvidas sobre o sistema de notificações:

1. Verificar logs do backend
2. Verificar status do Evolution API
3. Consultar tabela `notification_logs`
4. Verificar configurações do usuário na tabela `users`

**Documentos relacionados:**
- `INTEGRACAO-WHATSAPP-CONCLUIDA.md` - Detalhes da integração WhatsApp
- `STATUS-WHATSAPP-ATUAL.md` - Status atual do WhatsApp
- `BAILEYS-EVOLUTION-FUNCIONANDO.md` - Detalhes técnicos do Evolution API

