# 🔧 Solução Final: Acesso ao Banco de Dados

**Data:** 19/11/2025  
**Problema:** Container Docker não consegue acessar PostgreSQL  
**Status:** ✅ SOLUÇÕES ALTERNATIVAS CRIADAS

---

## 🔴 Problema Identificado

O container Docker não consegue acessar o PostgreSQL porque:
1. ❌ Host não consegue acessar `82.25.92.217:5432` (PostgreSQL pode estar apenas em localhost)
2. ❌ Container não consegue acessar IP externo (problema de rede Docker)
3. ❌ `host.docker.internal` não funciona no Linux sem configuração adicional

---

## ✅ Soluções Implementadas

### Solução 1: **network_mode: host** (Recomendado se PostgreSQL está em localhost)

Criado `docker-compose.host-network.yml` que usa `network_mode: host` para o backend:

**Vantagens:**
- ✅ Container acessa `localhost` diretamente
- ✅ Funciona se PostgreSQL está apenas em localhost
- ✅ Mais simples e direto
- ✅ Sem necessidade de configurar `extra_hosts`

**Como usar:**
```bash
docker-compose -f docker-compose.host-network.yml up -d
```

### Solução 2: **Configurar PostgreSQL para aceitar conexões remotas**

Se PostgreSQL precisa aceitar conexões remotas:

```bash
# Configurar PostgreSQL
./configurar-postgresql-remoto.sh

# Depois usar docker-compose.yml normal
docker-compose up -d
```

### Solução 3: **Usar localhost no DATABASE_URL**

Atualizado `docker-compose.yml` para usar `localhost` em vez de IP externo:

```yaml
environment:
  - DATABASE_URL=postgresql://root:<redacted-legacy-password-encoded>@localhost:5432/dbrief
```

**Nota:** Isso funciona apenas se usar `network_mode: host` ou se PostgreSQL aceitar conexões remotas.

---

## 🚀 Como Resolver no Servidor

### Passo 1: Verificar PostgreSQL Local

```bash
ssh root@82.25.92.217
cd ~/debrief
git pull

# Verificar PostgreSQL
./verificar-postgresql-local.sh
```

Este script verifica:
- ✅ Se PostgreSQL está rodando
- ✅ Em qual porta está escutando
- ✅ Se aceita conexões locais
- ✅ Se aceita conexões remotas
- ✅ Configuração atual

### Passo 2: Solucionar Automaticamente

```bash
# Script que detecta o problema e aplica solução
./solucionar-acesso-banco.sh
```

Este script:
- ✅ Verifica PostgreSQL local
- ✅ Testa conexão
- ✅ Aplica solução apropriada
- ✅ Inicia containers

### Passo 3: Solução Manual (Se necessário)

#### Opção A: Usar network_mode: host (Recomendado)

```bash
# Parar containers atuais
docker-compose down

# Usar versão com network_mode: host
docker-compose -f docker-compose.host-network.yml build --no-cache backend
docker-compose -f docker-compose.host-network.yml up -d

# Verificar logs
docker-compose -f docker-compose.host-network.yml logs backend | tail -50
```

#### Opção B: Configurar PostgreSQL para aceitar conexões remotas

```bash
# Configurar PostgreSQL
./configurar-postgresql-remoto.sh

# Rebuild backend
docker-compose build --no-cache backend
docker-compose up -d backend
```

---

## 📊 Comparação das Soluções

| Solução | Quando Usar | Vantagens | Desvantagens |
|---------|-------------|-----------|---------------|
| **network_mode: host** | PostgreSQL em localhost | ✅ Simples<br>✅ Funciona imediatamente<br>✅ Sem configuração extra | ⚠️ Container usa rede do host<br>⚠️ Portas não isoladas |
| **Configurar PostgreSQL remoto** | Precisa aceitar conexões remotas | ✅ Containers isolados<br>✅ Mais seguro | ⚠️ Requer configuração PostgreSQL<br>⚠️ Pode precisar firewall |
| **host.docker.internal** | Docker Desktop ou Linux configurado | ✅ Containers isolados | ⚠️ Não funciona no Linux por padrão<br>⚠️ Requer extra_hosts |

---

## 🔍 Diagnóstico Passo a Passo

### 1. Verificar se PostgreSQL está rodando

```bash
sudo systemctl status postgresql
```

### 2. Verificar em qual endereço está escutando

```bash
sudo netstat -tlnp | grep postgres
```

**Se mostrar `127.0.0.1:5432`:**
- ✅ PostgreSQL está apenas em localhost
- ✅ Use `network_mode: host`

**Se mostrar `0.0.0.0:5432`:**
- ✅ PostgreSQL aceita conexões remotas
- ✅ Pode usar `docker-compose.yml` normal

### 3. Testar conexão local

```bash
export PGPASSWORD="<redacted-db-password>"
psql -h localhost -p 5432 -U root -d dbrief -c "SELECT 1;"
unset PGPASSWORD
```

### 4. Testar conexão do container

```bash
# Com network_mode: host
docker-compose -f docker-compose.host-network.yml exec backend python3 << EOF
import psycopg2
conn = psycopg2.connect(
    host="localhost",
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

- [ ] Verificar PostgreSQL: `./verificar-postgresql-local.sh`
- [ ] Testar conexão local: `psql -h localhost -U root -d dbrief`
- [ ] Decidir solução (network_mode: host ou configurar remoto)
- [ ] Aplicar solução: `./solucionar-acesso-banco.sh` ou manual
- [ ] Rebuild backend: `docker-compose build --no-cache backend`
- [ ] Iniciar containers: `docker-compose up -d`
- [ ] Verificar logs: `docker-compose logs backend | tail -50`
- [ ] Verificar status: `docker-compose ps backend`
- [ ] Testar conexão do container
- [ ] Verificar que backend está healthy

---

## 🎯 Resultado Esperado

Após aplicar a solução:

1. **PostgreSQL acessível localmente:**
   ```bash
   psql -h localhost -U root -d dbrief -c "SELECT 1;"
   # ✅ Funciona
   ```

2. **Backend inicia com sucesso:**
   ```
   🚀 DeBrief API v1.0.0 iniciando...
   ✅ Banco de dados inicializado e tabelas criadas
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

## 📝 Arquivos Criados

- ✅ `docker-compose.host-network.yml` - Versão com network_mode: host
- ✅ `verificar-postgresql-local.sh` - Script de verificação
- ✅ `solucionar-acesso-banco.sh` - Script de solução automática
- ✅ `SOLUCAO_FINAL_ACESSO_BANCO.md` - Documentação completa

---

## 🚨 Troubleshooting

### Problema: "PostgreSQL não está rodando"

```bash
# Iniciar PostgreSQL
sudo systemctl start postgresql
sudo systemctl enable postgresql

# Verificar status
sudo systemctl status postgresql
```

### Problema: "Banco dbrief não existe"

```bash
# Criar banco
sudo -u postgres psql -c "CREATE DATABASE dbrief;"

# Criar usuário
sudo -u postgres psql -c "CREATE USER root WITH PASSWORD '<redacted-db-password>';"
sudo -u postgres psql -c "GRANT ALL PRIVILEGES ON DATABASE dbrief TO root;"
```

### Problema: "Usuário root não existe"

```bash
# Criar usuário
sudo -u postgres psql -c "CREATE USER root WITH PASSWORD '<redacted-db-password>';"
sudo -u postgres psql -c "ALTER USER root CREATEDB;"
```

### Problema: "Ainda não funciona após aplicar solução"

```bash
# Verificar logs detalhados
docker-compose logs backend | grep -i "error\|timeout\|connection"

# Testar conexão manualmente
docker-compose exec backend python3 << EOF
import psycopg2
try:
    conn = psycopg2.connect(
        host="localhost",
        port=5432,
        database="dbrief",
        user="root",
        password="<redacted-db-password>",
        connect_timeout=5
    )
    print("✅ Conexão OK!")
    conn.close()
except Exception as e:
    print(f"❌ Erro: {e}")
EOF
```

---

**✅ Múltiplas soluções disponíveis!**

**🔧 Execute `./solucionar-acesso-banco.sh` no servidor para aplicar automaticamente!**

