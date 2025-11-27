# Template de Notificação - Usuário Cadastrado

## 📋 Resumo

Foi implementado um sistema completo de notificação via WhatsApp para quando um novo usuário é cadastrado no sistema DeBrief. O novo usuário recebe automaticamente uma mensagem de boas-vindas pedindo para adicionar o número do DeBrief nos contatos.

## ✅ Implementações Realizadas

### 1. Schema de Templates (`backend/app/schemas/template_mensagem.py`)
- ✅ Adicionado tipo de evento `usuario_cadastrado` no validador
- ✅ Suporte tanto no `TemplateMensagemCreate` quanto no `TemplateMensagemUpdate`

### 2. Model de Templates (`backend/app/models/template_mensagem.py`)
- ✅ Adicionadas novas variáveis disponíveis:
  - `usuario_username`: Username do usuário
  - `whatsapp_debrief`: Número do WhatsApp do DeBrief
- ✅ Corrigido método `get_by_tipo_evento` removendo filtro `deleted_at` (campo não existe)

### 3. Serviço de Notificações (`backend/app/services/notification_whatsapp.py`)
- ✅ Criado método `notificar_usuario_cadastrado(usuario: User)`
- ✅ Método verifica:
  - Se há configuração WhatsApp ativa
  - Se o usuário tem WhatsApp cadastrado
  - Busca template do tipo `usuario_cadastrado`
  - Renderiza mensagem com variáveis do usuário
  - Envia notificação individual
  - Registra log de notificação

### 4. Endpoints de Criação de Usuário
- ✅ **`backend/app/api/endpoints/usuarios.py`**:
  - Adicionado envio de notificação no endpoint `POST /usuarios/`
  - Adicionado envio de notificação na reativação de usuário inativo
- ✅ **`backend/app/api/endpoints/auth.py`**:
  - Adicionado envio de notificação no endpoint `POST /auth/register`

### 5. Script SQL (`scripts/criar-template-usuario-cadastrado.sql`)
- ✅ Script completo para inserir o template no banco de dados
- ✅ Usa `ON CONFLICT` para atualizar se já existir
- ✅ Inclui query de verificação

## 📝 Template de Mensagem

O template criado contém a seguinte mensagem:

```
👋 *Bem-vindo ao DeBrief!*

Olá *{usuario_nome}*,

Você foi cadastrado com sucesso no sistema DeBrief!

📱 *Importante:* Para receber notificações sobre suas demandas, adicione o número do DeBrief nos seus contatos do WhatsApp:

📞 *{whatsapp_debrief}*

Após adicionar o número, você receberá notificações importantes sobre:
✅ Novas demandas criadas
✅ Atualizações de status
✅ Lembretes de prazo
✅ Outras informações relevantes

Seu usuário: *{usuario_username}*
Email: *{usuario_email}*

Bem-vindo e bom trabalho! 🚀

_Equipe DeBrief_
```

## 🔧 Variáveis Disponíveis no Template

- `{usuario_nome}`: Nome completo do usuário (ou username se não tiver nome)
- `{usuario_username}`: Username do usuário
- `{usuario_email}`: Email do usuário
- `{whatsapp_debrief}`: Número do WhatsApp do DeBrief (5585996039026)
- `{cliente_nome}`: Nome do cliente (se usuário for tipo cliente)

## 🚀 Como Usar

### 1. Criar o Template no Banco de Dados

Execute o script SQL:

```bash
# Via DBeaver ou psql
psql -h localhost -p 5433 -U postgres -d dbrief -f scripts/criar-template-usuario-cadastrado.sql
```

Ou execute diretamente no DBeaver após conectar ao banco.

### 2. Testar a Funcionalidade

1. Crie um novo usuário via interface web ou API
2. Certifique-se de que o usuário tem WhatsApp cadastrado
3. A notificação será enviada automaticamente após o cadastro

### 3. Editar o Template

O template pode ser editado via interface web em:
- `/admin/templates-mensagens` (apenas usuários Master)

## 📊 Fluxo de Execução

1. **Usuário é cadastrado** → Endpoint `POST /usuarios/` ou `POST /auth/register`
2. **Usuário é salvo no banco** → Commit realizado
3. **Serviço de notificação é chamado** → `NotificationWhatsAppService.notificar_usuario_cadastrado()`
4. **Verificações**:
   - Configuração WhatsApp ativa? ✅
   - Usuário tem WhatsApp? ✅
   - Template existe? ✅
5. **Template é renderizado** → Variáveis substituídas
6. **Mensagem enviada** → Via Z-API
7. **Log registrado** → `notification_logs` com status

## ⚠️ Observações Importantes

1. **Não bloqueia criação**: Se a notificação falhar, o usuário ainda é criado normalmente
2. **Logs de erro**: Todos os erros são registrados em `notification_logs`
3. **Reativação**: Usuários inativos que são reativados também recebem a notificação
4. **Sem WhatsApp**: Se o usuário não tiver WhatsApp cadastrado, a notificação não é enviada (mas não gera erro)

## 🔍 Verificar Logs

Para verificar se as notificações estão sendo enviadas:

```sql
SELECT 
    id,
    usuario_id,
    destinatario,
    status,
    erro_mensagem,
    enviado_em,
    metadata
FROM notification_logs
WHERE metadata LIKE '%usuario_cadastrado%'
ORDER BY created_at DESC;
```

## 📞 Número do WhatsApp do DeBrief

O número configurado é: **5585996039026**

Este número é obtido automaticamente de `settings.ZAPI_PHONE_NUMBER`.

## ✨ Próximos Passos (Opcional)

- [ ] Adicionar opção para desabilitar notificação de cadastro
- [ ] Criar template personalizado por cliente
- [ ] Adicionar link direto para adicionar contato (wa.me)
- [ ] Enviar notificação também por email (se configurado)

---

**Data de Implementação**: 2025-01-15  
**Status**: ✅ Completo e Funcional



