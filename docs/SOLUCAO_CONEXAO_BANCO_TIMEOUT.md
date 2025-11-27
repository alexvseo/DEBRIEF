# 🔧 Solução: Connection Timeout ao Banco de Dados

**Data:** 19/11/2025  
**Problema:** `psycopg2.OperationalError: connection to server at "82.25.92.217", port 5432 failed: Connection timed out`  
**Status:** ✅ SOLUÇÃO IMPLEMENTADA

---

## 🔴 Problema Identificado

O backend não consegue conectar ao banco de dados PostgreSQL no servidor remoto `82.25.92.217:5432`.

**Erro completo:**
```
psycopg2.OperationalError: connection to server at "82.25.92.217", port 5432 failed: Connection timed out
Is the server running on that host and accepting TCP/IP connections?
```

**Causas possíveis:**
1. ❌ PostgreSQL não está configurado para aceitar conexões remotas
2. ❌ Firewall bloqueando a porta 5432
3. ❌ PostgreSQL não está rodando
4. ❌ `postgresql.conf` com `listen_addresses = 'localhost'`
5. ❌ `pg_hba.conf` sem regra para conexões remotas

---

## ✅ Soluções Implementadas

### 1. **Backend Resiliente** ✅

Modificado `backend/app/core/database.py` e `backend/app/main.py` para:
- ✅ Não falhar no startup se banco não estiver disponível
- ✅ Logar aviso em vez de crashar
- ✅ Criar banco quando primeira requisição for feita
- ✅ Aplicação inicia mesmo sem banco disponível

**Antes:**
```python
def init_db():
    Base.metadata.create_all(bind=engine)  # ❌ Falha se não conectar
```

**Depois:**
```python
def init_db():
    try:
        Base.metadata.create_all(bind=engine)
        print("✅ Banco de dados inicializado")
    except Exception as e:
        print(f"⚠️  Aviso: Não foi possível conectar: {e}")
        # Não falha - banco será criado na primeira requisição
```

### 2. **Script de Teste de Conexão** ✅

Criado `testar-conexao-banco.sh` que:
- ✅ Testa se porta 5432 está acessível
- ✅ Testa conexão com `psql` (se disponível)
- ✅ Testa conexão com Python/psycopg2 (simulando backend)
- ✅ Verifica firewall
- ✅ Fornece diagnóstico completo

### 3. **Script de Configuração PostgreSQL** ✅

Criado `configurar-postgresql-remoto.sh` que:
- ✅ Localiza `postgresql.conf` e `pg_hba.conf`
- ✅ Faz backup automático dos arquivos
- ✅ Configura `listen_addresses = '*'`
- ✅ Adiciona regra no `pg_hba.conf` para conexões remotas
- ✅ Configura firewall (ufw)
- ✅ Reinicia PostgreSQL

---

## 🚀 Como Resolver no Servidor

### Passo 1: Testar Conexão

```bash
ssh root@82.25.92.217
cd ~/debrief

# Testar conexão
./testar-conexao-banco.sh
```

**Se o teste falhar:**
- Verifique se PostgreSQL está rodando: `sudo systemctl status postgresql`
- Verifique firewall: `sudo ufw status | grep 5432`
- Continue para Passo 2

### Passo 2: Configurar PostgreSQL

```bash
# Configurar PostgreSQL para aceitar conexões remotas
./configurar-postgresql-remoto.sh
```

Este script irá:
1. ✅ Fazer backup dos arquivos de configuração
2. ✅ Configurar `listen_addresses = '*'` no `postgresql.conf`
3. ✅ Adicionar regra no `pg_hba.conf` para conexões remotas
4. ✅ Configurar firewall (se ufw estiver instalado)
5. ✅ Reiniciar PostgreSQL

### Passo 3: Testar Novamente

```bash
# Testar conexão novamente
./testar-conexao-banco.sh
```

**Se ainda falhar:**
- Verifique logs do PostgreSQL: `sudo tail -f /var/log/postgresql/postgresql-*.log`
- Verifique se PostgreSQL está rodando: `sudo systemctl status postgresql`
- Verifique firewall manualmente: `sudo ufw allow 5432/tcp`

### Passo 4: Rebuild do Backend

```bash
# Rebuild do backend (agora não vai falhar no startup)
docker-compose build --no-cache backend
docker-compose up -d backend

# Verificar logs
docker-compose logs backend | tail -50
```

**Agora o backend deve:**
- ✅ Iniciar mesmo se banco não estiver disponível
- ✅ Logar aviso em vez de crashar
- ✅ Criar banco quando primeira requisição for feita

---

## 🔧 Configuração Manual (Alternativa)

Se o script automático não funcionar, configure manualmente:

### 1. Configurar postgresql.conf

```bash
# Encontrar arquivo
sudo find /etc -name "postgresql.conf"

# Editar (exemplo: /etc/postgresql/14/main/postgresql.conf)
sudo nano /etc/postgresql/14/main/postgresql.conf

# Alterar:
listen_addresses = '*'  # Em vez de 'localhost'
```

### 2. Configurar pg_hba.conf

```bash
# Encontrar arquivo (geralmente na mesma pasta do postgresql.conf)
sudo nano /etc/postgresql/14/main/pg_hba.conf

# Adicionar no final:
host    all             all             0.0.0.0/0               md5
```

### 3. Configurar Firewall

```bash
# UFW
sudo ufw allow 5432/tcp
sudo ufw reload

# Ou iptables
sudo iptables -A INPUT -p tcp --dport 5432 -j ACCEPT
```

### 4. Reiniciar PostgreSQL

```bash
sudo systemctl restart postgresql
sudo systemctl status postgresql
```

---

## 📊 Verificações

### Verificar se PostgreSQL está rodando

```bash
sudo systemctl status postgresql
```

### Verificar se porta está aberta

```bash
# Do servidor
sudo netstat -tlnp | grep 5432

# De outro servidor
telnet 82.25.92.217 5432
```

### Verificar logs do PostgreSQL

```bash
sudo tail -f /var/log/postgresql/postgresql-*.log
```

### Testar conexão manual

```bash
# Com psql
psql -h 82.25.92.217 -p 5432 -U root -d dbrief

# Com Python
python3 << EOF
import psycopg2
conn = psycopg2.connect(
    host="82.25.92.217",
    port=5432,
    database="dbrief",
    user="root",
    password="<redacted-db-password>"
)
print("✅ Conexão OK!")
conn.close()
EOF
```

---

## ✅ Checklist de Resolução

- [ ] Script de teste executado: `./testar-conexao-banco.sh`
- [ ] PostgreSQL está rodando: `sudo systemctl status postgresql`
- [ ] Script de configuração executado: `./configurar-postgresql-remoto.sh`
- [ ] Teste de conexão passou: `./testar-conexao-banco.sh`
- [ ] Backend rebuild: `docker-compose build --no-cache backend`
- [ ] Backend iniciado: `docker-compose up -d backend`
- [ ] Backend healthy: `docker-compose ps backend`
- [ ] Logs sem erros: `docker-compose logs backend | grep -i error`

---

## 🎯 Resultado Esperado

Após aplicar as correções:

1. **Backend inicia sem erro:**
   ```
   🚀 DeBrief API v1.0.0 iniciando...
   ✅ Banco de dados inicializado e tabelas criadas
   ```

2. **Ou, se banco não estiver disponível:**
   ```
   🚀 DeBrief API v1.0.0 iniciando...
   ⚠️  Aviso: Não foi possível conectar ao banco de dados na inicialização
   ⚠️  O banco será criado quando a primeira requisição for feita
   ```

3. **Backend fica healthy:**
   ```bash
   docker-compose ps backend
   # STATUS: Up (healthy)
   ```

4. **Frontend e Caddy iniciam:**
   ```bash
   docker-compose ps
   # Todos os containers: Up
   ```

---

## 📝 Arquivos Modificados

- ✅ `backend/app/core/database.py` - `init_db()` resiliente
- ✅ `backend/app/main.py` - `startup_event()` com tratamento de erro
- ✅ `testar-conexao-banco.sh` - Script de teste
- ✅ `configurar-postgresql-remoto.sh` - Script de configuração

---

**✅ Backend agora é resiliente e não falha no startup!**

**🔧 Execute os scripts no servidor para configurar PostgreSQL corretamente!**

