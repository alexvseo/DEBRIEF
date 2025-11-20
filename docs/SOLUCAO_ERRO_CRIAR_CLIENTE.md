# 🔧 Solução: Erro ao Criar Cliente

## ❌ Problema

Ao tentar criar um cliente, aparece o erro: **"Erro ao salvar cliente"** sem detalhes.

## 🔍 Possíveis Causas

### 1. Validação de WhatsApp Group ID
O campo `whatsapp_group_id` **deve terminar com `@g.us`**

**Formato correto:**
```
99999999-1234567890@g.us
```

**Formato incorreto:**
```
99999999-1234567890
99999999-1234567890@whatsapp.com
```

### 2. Nome Duplicado
Não é possível criar dois clientes com o mesmo nome (case insensitive).

### 3. Nome Vazio ou Muito Curto
O nome deve ter pelo menos 3 caracteres.

### 4. Problema de Permissão
Apenas usuários **Master** podem criar clientes.

### 5. Problema de Conexão com Banco
O backend pode não estar conseguindo acessar o PostgreSQL.

## ✅ Soluções

### Solução 1: Verificar Mensagem de Erro Detalhada

Após a atualização, o frontend agora mostra a mensagem específica do backend. Tente criar o cliente novamente e verifique:

1. **Abra o Console do Navegador** (F12 → Console)
2. **Tente criar o cliente**
3. **Veja a mensagem de erro detalhada** no alert e no console

### Solução 2: Verificar Formato do WhatsApp Group ID

Se estiver preenchendo o campo WhatsApp Group ID, certifique-se de que termina com `@g.us`:

```
✅ Correto: 99999999-1234567890@g.us
❌ Incorreto: 99999999-1234567890
```

**Dica:** Se não tiver o ID do grupo WhatsApp, deixe o campo **vazio**.

### Solução 3: Verificar Nome Duplicado

Se o erro for "Cliente com nome 'X' já existe", escolha um nome diferente.

### Solução 4: Testar via API Diretamente

No servidor, execute o script de teste:

```bash
cd /root/debrief
git pull origin main
./scripts/diagnostico/testar-criar-cliente.sh
```

Ou manualmente:

```bash
# 1. Fazer login
TOKEN=$(curl -s -X POST "http://82.25.92.217:2022/api/auth/login" \
  -H "Content-Type: application/x-www-form-urlencoded" \
  -d "username=admin&password=sua_senha" | grep -o '"access_token":"[^"]*' | cut -d'"' -f4)

# 2. Criar cliente
curl -X POST "http://82.25.92.217:2022/api/clientes/" \
  -H "Authorization: Bearer ${TOKEN}" \
  -H "Content-Type: application/json" \
  -d '{
    "nome": "Cliente Teste",
    "whatsapp_group_id": "99999999-1234567890@g.us",
    "trello_member_id": "3def456",
    "ativo": true
  }'
```

### Solução 5: Verificar Logs do Backend

```bash
docker-compose logs backend | grep -i -E "cliente|error|exception" | tail -20
```

### Solução 6: Verificar Permissões do Usuário

Certifique-se de que está logado como usuário **Master**:

```bash
# Verificar tipo de usuário no banco
sudo -u postgres psql -d dbrief -c "SELECT username, tipo, ativo FROM users WHERE username = 'seu_usuario';"
```

O campo `tipo` deve ser `master`.

## 📋 Checklist de Diagnóstico

- [ ] WhatsApp Group ID termina com `@g.us` (ou está vazio)
- [ ] Nome do cliente tem pelo menos 3 caracteres
- [ ] Nome do cliente não está duplicado
- [ ] Usuário logado é do tipo Master
- [ ] Backend está conectado ao banco (ver logs)
- [ ] Console do navegador mostra erro detalhado

## 🔍 Exemplos de Erros Comuns

### Erro: "WhatsApp group ID deve terminar com @g.us"
**Solução:** Adicione `@g.us` ao final do ID ou deixe o campo vazio.

### Erro: "Cliente com nome 'X' já existe"
**Solução:** Escolha um nome diferente.

### Erro: "Nome não pode ser vazio"
**Solução:** Preencha o campo Nome do Cliente.

### Erro: "Permissões insuficientes"
**Solução:** Faça login como usuário Master.

### Erro: "Connection refused" ou "Database error"
**Solução:** Verifique conexão do backend com PostgreSQL:
```bash
./scripts/diagnostico/verificar-postgresql-servidor.sh
./scripts/correcao/corrigir-postgresql-servidor.sh
```

## 🚀 Próximos Passos

1. **Atualizar o frontend no servidor:**
   ```bash
   cd /root/debrief
   git pull origin main
   docker-compose restart frontend
   ```

2. **Tentar criar cliente novamente** e verificar a mensagem de erro detalhada

3. **Se o erro persistir**, execute o script de diagnóstico:
   ```bash
   ./scripts/diagnostico/testar-criar-cliente.sh
   ```

---

**Última atualização:** 2025-01-20

