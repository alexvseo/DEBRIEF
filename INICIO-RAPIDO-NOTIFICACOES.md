# 🚀 Início Rápido - Notificações WhatsApp

## ⚡ Setup em 5 Minutos

### Passo 1: Verificar WhatsApp Evolution API (30 segundos)

```bash
# Verificar se está conectado
curl http://localhost:21465/instance/connectionState/debrief \
  -H "apikey: debrief-wpp-58a2b7dda7da9474958e2a853062d5d5"

# Se não estiver conectado, reconectar:
./reconectar-whatsapp-evolution.sh
```

**Resposta esperada:** `"state": "open"`

---

### Passo 2: Configurar Seu WhatsApp (1 minuto)

**Opção A: Via Banco de Dados (mais rápido)**

```bash
# 1. Conectar ao banco
./conectar-banco-correto.sh

# 2. Em outra aba, abrir DBeaver
# Host: localhost
# Port: 5433
# Database: dbrief
# User: postgres
# Password: Mslestra@2025db

# 3. Executar query (substituir valores):
```

```sql
UPDATE users 
SET 
    whatsapp = '5585991042626',  -- SEU NÚMERO AQUI
    receber_notificacoes = true
WHERE email = 'seu.email@example.com';  -- SEU EMAIL AQUI

-- Verificar:
SELECT username, email, whatsapp, receber_notificacoes, tipo, cliente_id 
FROM users 
WHERE email = 'seu.email@example.com';
```

**Opção B: Via API**

```bash
# 1. Fazer login
TOKEN=$(curl -s -X POST http://localhost:8000/api/auth/login \
  -H "Content-Type: application/json" \
  -d '{"username": "seu.email@example.com", "password": "sua-senha"}' \
  | jq -r '.access_token')

# 2. Configurar WhatsApp
curl -X PUT http://localhost:8000/api/usuarios/me/notificacoes \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"whatsapp": "5585991042626", "receber_notificacoes": true}'
```

---

### Passo 3: Criar Demanda de Teste (1 minuto)

1. Abrir interface web: http://debrief.interce.com.br
2. Fazer login
3. Clicar em "Nova Demanda"
4. Preencher campos e criar

**OU** usar o script automático:

```bash
./testar-notificacoes.sh
```

---

### Passo 4: Verificar Notificação (10 segundos)

1. **Abrir seu WhatsApp** 📱
2. **Procurar mensagem** do número: +55 85 91042626
3. **Ler notificação** 🔔

---

## 📋 Formato do Número WhatsApp

✅ **CORRETO:**
- `5585991042626` (Brasil, Ceará, celular)
- `5511999887766` (Brasil, SP, celular)

❌ **INCORRETO:**
- `85991042626` (falta código do país 55)
- `(85) 99104-2626` (tem caracteres especiais)
- `55 85 99104-2626` (tem espaços)

**Regra:** Apenas dígitos, com código do país!

---

## ✅ Checklist Rápido

Antes de testar, verifique:

- [ ] Evolution API conectada (`"state": "open"`)
- [ ] Número WhatsApp cadastrado no banco
- [ ] Campo `receber_notificacoes = true`
- [ ] Usuário está `ativo = true`
- [ ] Backend rodando (porta 8000)

---

## 🧪 Testar Agora

### Teste Completo Automatizado

```bash
./testar-notificacoes.sh
```

Este script irá:
1. ✅ Verificar configurações
2. ✅ Configurar seu WhatsApp
3. ✅ Criar demanda de teste
4. ✅ Verificar envio
5. ✅ Mostrar logs

**Tempo:** ~2 minutos

---

## 🔍 Verificar Se Funcionou

### Via Banco de Dados

```sql
-- Ver últimas notificações
SELECT 
    created_at,
    status,
    dados_enviados->>'usuario_nome' as usuario,
    dados_enviados->>'whatsapp' as whatsapp
FROM notification_logs
WHERE tipo = 'whatsapp'
ORDER BY created_at DESC
LIMIT 5;
```

### Via Logs do Backend

```bash
# Ver logs em tempo real
tail -f backend/logs/app.log | grep -i "notific"
```

---

## ❓ Problemas Comuns

### "Não recebi notificação"

```sql
-- Verificar sua configuração
SELECT username, email, whatsapp, receber_notificacoes, ativo 
FROM users 
WHERE email = 'seu.email@example.com';
```

**Solução:** Todos os campos devem estar preenchidos e `true`

### "WhatsApp desconectado"

```bash
./reconectar-whatsapp-evolution.sh
```

### "Erro ao criar demanda"

Verifique:
1. Backend rodando? → `curl http://localhost:8000/health`
2. Banco conectado? → `./conectar-banco-correto.sh`

---

## 🎯 Quem Recebe Notificações?

### Usuário Comum (tipo: cliente)
- ✅ Recebe notificações **apenas do seu cliente**
- ❌ NÃO recebe de outros clientes

**Exemplo:**
- Usuário vinculado a "Russas"
- Demanda criada para "Russas" → **RECEBE** ✅
- Demanda criada para "Quixadá" → **NÃO RECEBE** ❌

### Usuário Master (tipo: master)
- ✅ Recebe **TODAS** as notificações
- ✅ Independente do cliente

---

## 📱 Exemplo de Notificação

Quando criar uma demanda, você receberá:

```
🔔 Nova Demanda Criada!

📋 Demanda: Implementar portal do cidadão
🏢 Cliente: Prefeitura de Russas
🏛️ Secretaria: Secretaria de Tecnologia
📌 Tipo: Sistema Web
🟡 Prioridade: Média
📅 Prazo: 31/12/2024

👤 Solicitante: João Silva

🔗 Ver no Sistema: https://trello.com/c/ABC123

_ID: 550e8400-e29b-41d4-a716-446655440000_
```

---

## 🎉 Pronto!

Agora você está recebendo notificações WhatsApp automaticamente! 🚀

**Próximos Eventos:**
- 🔔 Nova demanda criada
- 🔄 Demanda atualizada
- 💻 Status mudou para "em desenvolvimento"
- ✅ Demanda concluída
- 🗑️ Demanda excluída

---

## 📚 Documentação Completa

Para mais detalhes, consulte:

- `NOTIFICACOES-WHATSAPP.md` - Guia completo
- `RESUMO-IMPLEMENTACAO-NOTIFICACOES.md` - Resumo técnico
- `configurar-whatsapp-usuarios.sql` - Queries SQL prontas

---

**Dúvidas?** Verifique os logs ou consulte a documentação completa! 🤓

