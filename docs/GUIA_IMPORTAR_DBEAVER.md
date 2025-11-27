# 📊 Guia: Importar Script SQL no DBeaver

**Sistema:** DeBrief  
**Banco:** PostgreSQL  
**Arquivo:** `database_schema.sql`

---

## 🎯 Objetivo

Importar o script SQL completo do banco de dados do sistema DeBrief no DBeaver para visualizar e gerenciar a estrutura do banco.

---

## 📋 Pré-requisitos

1. ✅ **DBeaver instalado** ([Download](https://dbeaver.io/download/))
2. ✅ **Conexão com PostgreSQL configurada**
3. ✅ **Banco de dados `dbrief` criado**
4. ✅ **Credenciais de acesso ao banco**

---

## 🔧 Passo a Passo

### 1️⃣ Conectar ao Banco de Dados

1. Abra o **DBeaver**
2. Clique em **"Nova Conexão"** (ícone de plug) ou `Ctrl+Shift+N`
3. Selecione **PostgreSQL**
4. Preencha os dados de conexão:

   ```
   Host:     82.25.92.217
   Port:     5432
   Database: dbrief
   Username: root
   Password: <redacted-db-password>
   ```

5. Clique em **"Testar Conexão"**
6. Se tudo estiver OK, clique em **"Finalizar"**

---

### 2️⃣ Abrir o Script SQL

1. No DBeaver, vá em **Arquivo → Abrir Arquivo** (`Ctrl+O`)
2. Navegue até o arquivo: `database_schema.sql`
3. O script será aberto em uma nova aba

---

### 3️⃣ Executar o Script

#### Opção A: Executar Script Completo (Recomendado)

1. **Selecione todo o conteúdo** do script (`Ctrl+A`)
2. Clique com o botão direito → **"Executar SQL"** ou pressione `Ctrl+Enter`
3. Aguarde a execução (pode levar alguns segundos)
4. Verifique se apareceu **"Sucesso"** no console

#### Opção B: Executar por Seções

Se preferir executar por partes:

1. **Seção 1:** Tipos ENUM (linhas ~30-50)
2. **Seção 2:** Tabelas (linhas ~60-350)
3. **Seção 3:** Dados Iniciais (linhas ~360-500)
4. **Seção 4:** Verificações (linhas ~500+)

---

### 4️⃣ Verificar Resultado

#### Verificar Tabelas Criadas

Execute no console SQL do DBeaver:

```sql
SELECT 
    table_name,
    (SELECT COUNT(*) 
     FROM information_schema.columns 
     WHERE table_name = t.table_name) as colunas
FROM information_schema.tables t
WHERE table_schema = 'public' 
    AND table_type = 'BASE TABLE'
    AND table_name IN (
        'users', 'clientes', 'secretarias', 
        'tipos_demanda', 'prioridades', 
        'demandas', 'anexos', 'configuracoes'
    )
ORDER BY table_name;
```

**Resultado esperado:**
- ✅ 8 tabelas listadas

#### Verificar Dados Inseridos

```sql
SELECT 'users' as tabela, COUNT(*) as registros FROM users
UNION ALL
SELECT 'clientes', COUNT(*) FROM clientes
UNION ALL
SELECT 'secretarias', COUNT(*) FROM secretarias
UNION ALL
SELECT 'tipos_demanda', COUNT(*) FROM tipos_demanda
UNION ALL
SELECT 'prioridades', COUNT(*) FROM prioridades
UNION ALL
SELECT 'demandas', COUNT(*) FROM demandas
UNION ALL
SELECT 'anexos', COUNT(*) FROM anexos
UNION ALL
SELECT 'configuracoes', COUNT(*) FROM configuracoes;
```

**Resultado esperado:**
- ✅ `users`: 2 registros (admin e cliente)
- ✅ `clientes`: 1 registro
- ✅ `secretarias`: 6 registros
- ✅ `tipos_demanda`: 4 registros
- ✅ `prioridades`: 4 registros
- ✅ `demandas`: 3 registros
- ✅ `anexos`: 0 registros (vazio inicialmente)
- ✅ `configuracoes`: 10 registros

---

## 🎨 Explorar o Banco no DBeaver

### Visualizar Estrutura

1. No **Navegador de Banco de Dados** (lado esquerdo)
2. Expanda: `dbrief → Schemas → public → Tables`
3. Você verá todas as 8 tabelas criadas

### Visualizar Dados

1. Clique com botão direito em uma tabela (ex: `users`)
2. Selecione **"Ver Dados"** ou `F4`
3. Os dados serão exibidos em formato de tabela

### Visualizar Estrutura de Tabela

1. Clique com botão direito em uma tabela
2. Selecione **"Ver Estrutura"** ou `F4`
3. Veja colunas, tipos, constraints, índices

### Executar Queries

1. Clique com botão direito no banco `dbrief`
2. Selecione **"SQL Editor → Nova Consulta SQL"**
3. Digite suas queries e execute com `Ctrl+Enter`

---

## 🔍 Queries Úteis

### Ver Todos os Usuários

```sql
SELECT 
    id,
    username,
    email,
    nome_completo,
    tipo,
    ativo,
    created_at
FROM users
ORDER BY created_at DESC;
```

### Ver Demandas com Detalhes

```sql
SELECT 
    d.id,
    d.nome,
    d.status,
    d.prazo_final,
    u.nome_completo as usuario,
    c.nome as cliente,
    td.nome as tipo_demanda,
    p.nome as prioridade,
    s.nome as secretaria
FROM demandas d
LEFT JOIN users u ON d.usuario_id = u.id
LEFT JOIN clientes c ON d.cliente_id = c.id
LEFT JOIN tipos_demanda td ON d.tipo_demanda_id = td.id
LEFT JOIN prioridades p ON d.prioridade_id = p.id
LEFT JOIN secretarias s ON d.secretaria_id = s.id
ORDER BY d.created_at DESC;
```

### Ver Relacionamentos

```sql
-- Clientes com suas Secretarias
SELECT 
    c.nome as cliente,
    COUNT(s.id) as total_secretarias
FROM clientes c
LEFT JOIN secretarias s ON c.id = s.cliente_id
GROUP BY c.id, c.nome;

-- Usuários por Cliente
SELECT 
    c.nome as cliente,
    COUNT(u.id) as total_usuarios
FROM clientes c
LEFT JOIN users u ON c.id = u.cliente_id
GROUP BY c.id, c.nome;
```

---

## ⚠️ Problemas Comuns

### Erro: "relation already exists"

**Causa:** Tabelas já existem no banco.

**Solução:**
1. Opção 1: Descomentar a seção de limpeza no início do script
2. Opção 2: Dropar manualmente as tabelas:

```sql
DROP TABLE IF EXISTS anexos CASCADE;
DROP TABLE IF EXISTS demandas CASCADE;
DROP TABLE IF EXISTS configuracoes CASCADE;
DROP TABLE IF EXISTS secretarias CASCADE;
DROP TABLE IF EXISTS tipos_demanda CASCADE;
DROP TABLE IF EXISTS prioridades CASCADE;
DROP TABLE IF EXISTS users CASCADE;
DROP TABLE IF EXISTS clientes CASCADE;
DROP TYPE IF EXISTS tipousuario CASCADE;
DROP TYPE IF EXISTS statusdemanda CASCADE;
DROP TYPE IF EXISTS tipoconfiguracao CASCADE;
```

### Erro: "permission denied"

**Causa:** Usuário não tem permissão para criar tabelas.

**Solução:**
- Verificar se o usuário tem permissões de `CREATE TABLE`
- Conectar como superusuário (`postgres`)

### Erro: "duplicate key value"

**Causa:** Dados já existem (tentativa de inserir duplicados).

**Solução:**
- O script usa `ON CONFLICT DO NOTHING`, então é seguro executar múltiplas vezes
- Se ainda der erro, limpar os dados antes:

```sql
DELETE FROM demandas;
DELETE FROM anexos;
DELETE FROM users WHERE username IN ('admin', 'cliente');
DELETE FROM secretarias;
DELETE FROM clientes;
DELETE FROM tipos_demanda;
DELETE FROM prioridades;
DELETE FROM configuracoes;
```

---

## 📊 Estrutura do Banco

```
dbrief (Database)
└── public (Schema)
    ├── ENUMs
    │   ├── tipousuario (master, cliente)
    │   ├── statusdemanda (aberta, em_andamento, ...)
    │   └── tipoconfiguracao (trello, whatsapp, ...)
    │
    ├── Tabelas
    │   ├── clientes (1 registro)
    │   ├── users (2 registros)
    │   ├── secretarias (6 registros)
    │   ├── tipos_demanda (4 registros)
    │   ├── prioridades (4 registros)
    │   ├── demandas (3 registros)
    │   ├── anexos (0 registros)
    │   └── configuracoes (10 registros)
    │
    └── Relacionamentos
        ├── users → clientes (FK)
        ├── secretarias → clientes (FK)
        ├── demandas → users (FK)
        ├── demandas → clientes (FK)
        ├── demandas → tipos_demanda (FK)
        ├── demandas → secretarias (FK)
        ├── demandas → prioridades (FK)
        └── anexos → demandas (FK)
```

---

## 🔐 Credenciais de Acesso

Após importar o script, você pode testar o login:

- **👑 Master:**
  - Username: `admin`
  - Password: `admin123`

- **👤 Cliente:**
  - Username: `cliente`
  - Password: `cliente123`

---

## ✅ Checklist de Verificação

- [ ] Conexão com banco estabelecida
- [ ] Script SQL aberto no DBeaver
- [ ] Script executado com sucesso
- [ ] 8 tabelas criadas
- [ ] Dados iniciais inseridos
- [ ] Queries de verificação executadas
- [ ] Estrutura visualizada no navegador
- [ ] Dados visualizados corretamente

---

## 🚀 Próximos Passos

1. ✅ Explorar as tabelas no DBeaver
2. ✅ Executar queries personalizadas
3. ✅ Visualizar relacionamentos
4. ✅ Exportar dados se necessário
5. ✅ Conectar a aplicação ao banco

---

## 📝 Notas Importantes

- ⚠️ **Backup:** Sempre faça backup antes de executar scripts de modificação
- ⚠️ **Produção:** Em produção, use migrations (Alembic) ao invés de scripts SQL diretos
- ✅ **Desenvolvimento:** Este script é ideal para desenvolvimento e testes
- ✅ **DBeaver:** Use o DBeaver para visualização e análise de dados

---

**✅ Script importado com sucesso!**

**🎉 Agora você pode explorar o banco de dados do DeBrief no DBeaver!**

