# 🔌 Configuração DBeaver - DeBrief

## ✅ Túnel SSH Ativo

O túnel SSH está rodando e mantendo a conexão ativa automaticamente.

---

## 📝 Configuração da Conexão no DBeaver

### Passo 1: Nova Conexão PostgreSQL

1. Abra o DBeaver
2. Clique em **Database** → **New Database Connection**
3. Selecione **PostgreSQL**
4. Clique em **Next**

---

### Passo 2: Configurações Principais

```
┌─────────────────────────────────────────┐
│ Connection Settings                     │
├─────────────────────────────────────────┤
│                                         │
│  Host:       localhost                  │
│  Port:       5432                       │
│  Database:   dbrief                     │
│  Username:   postgres                   │
│  Password:   <redacted-db-password>            │
│                                         │
│  ☑ Show all databases                  │
│  ☑ Save password                       │
│                                         │
└─────────────────────────────────────────┘
```

**⚠️ IMPORTANTE:** 
- Use `localhost` (não 82.25.92.217)
- O túnel SSH redireciona localhost:5432 para o servidor

---

### Passo 3: Testar Conexão

1. Clique em **Test Connection**
2. Se aparecer erro sobre driver:
   - Clique em **Download** para baixar o driver PostgreSQL
   - Aguarde o download
   - Teste novamente

3. Você deve ver: **✅ Connected**

---

### Passo 4: Finalizar

1. Clique em **Finish**
2. A conexão "dbrief" aparecerá na lista
3. Clique duas vezes para conectar

---

## 🔍 Verificações Pós-Conexão

Após conectar, você deve ver:

### Databases (Bancos)
```
└── dbrief
    └── Schemas
        └── public
            └── Tables
                ├── usuarios
                ├── demandas
                ├── secretarias
                ├── configuracoes
                ├── notificacoes
                ├── anexos
                ├── comentarios
                └── (outras tabelas)
```

---

## 📊 Queries Úteis

### Ver todas as tabelas
```sql
SELECT table_name 
FROM information_schema.tables 
WHERE table_schema = 'public'
ORDER BY table_name;
```

### Contar registros
```sql
SELECT 
    'usuarios' as tabela, COUNT(*) as total FROM usuarios
UNION ALL
SELECT 'demandas', COUNT(*) FROM demandas
UNION ALL
SELECT 'secretarias', COUNT(*) FROM secretarias
UNION ALL
SELECT 'configuracoes', COUNT(*) FROM configuracoes;
```

### Ver últimas demandas
```sql
SELECT 
    id,
    titulo,
    status,
    prioridade,
    created_at,
    updated_at
FROM demandas
ORDER BY created_at DESC
LIMIT 10;
```

### Ver usuários ativos
```sql
SELECT 
    id,
    nome,
    email,
    role,
    is_active,
    created_at
FROM usuarios
WHERE is_active = true
ORDER BY created_at DESC;
```

---

## 🐛 Troubleshooting

### Erro: "Connection refused" ou "Connection timeout"
**Problema:** Túnel SSH não está ativo

**Solução:**
```bash
# Verifique se o túnel está rodando
ps aux | grep "ssh.*5432"

# Se não estiver, inicie novamente
./conectar-banco-ssh.sh
```

---

### Erro: "password authentication failed"
**Problema:** Senha incorreta

**Soluções possíveis:**
1. Tente senha: `<redacted-db-password>`
2. Tente senha: `<redacted-db-password>` (sem 'db')
3. Verifique o arquivo `.env` no servidor

---

### Erro: "database dbrief does not exist"
**Problema:** Banco de dados não foi criado

**Solução:**
```bash
# No servidor
ssh root@82.25.92.217
cd /var/www/debrief
docker exec debrief-backend python init_db.py
```

---

### Não vejo as tabelas
**Problema:** Tabelas não foram criadas ou está no schema errado

**Verificação:**
```sql
-- Ver todos os schemas
SELECT schema_name 
FROM information_schema.schemata;

-- Ver tabelas em todos os schemas
SELECT table_schema, table_name 
FROM information_schema.tables 
WHERE table_schema NOT IN ('pg_catalog', 'information_schema')
ORDER BY table_schema, table_name;
```

---

## 🔐 Segurança

### ✅ Boas Práticas Implementadas

1. **Túnel SSH:** Dados criptografados em trânsito
2. **Localhost:** Banco não exposto diretamente
3. **Keep-Alive:** Conexão estável sem quedas
4. **Timeout:** Desconexão automática se servidor não responder

### ⚠️ Lembrete

- Não compartilhe as credenciais
- Mantenha o terminal do túnel aberto
- Feche o túnel quando não estiver usando (Ctrl+C)

---

## 📞 Comandos Úteis

### Verificar se túnel está ativo
```bash
# Ver processo SSH
ps aux | grep "ssh.*5432"

# Testar porta local
nc -zv localhost 5432

# Conectar via psql
psql -h localhost -U postgres -d dbrief
```

### Encerrar túnel
```bash
# No terminal onde está rodando
Ctrl+C

# Ou encontrar e matar processo
pkill -f "ssh.*5432.*82.25.92.217"
```

### Reiniciar túnel
```bash
cd /Users/alexmini/Documents/PROJETOS\ DEV\ COM\ IA/DEBRIEF
./conectar-banco-ssh.sh
```

---

## ✅ Status da Conexão

```
┌────────────────────────────────────────┐
│  🔐 TÚNEL SSH: CONFIGURADO            │
│  📡 KEEP-ALIVE: ATIVO (60s)           │
│  🔌 PORTA LOCAL: 5432                 │
│  🌐 SERVIDOR: 82.25.92.217            │
│  💾 BANCO: dbrief                     │
└────────────────────────────────────────┘
```

**Pronto para usar! 🚀**





