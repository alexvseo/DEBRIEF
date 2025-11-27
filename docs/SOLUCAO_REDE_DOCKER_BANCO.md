# 🔧 Solução: Container Docker Não Consegue Acessar Banco no Host

**Data:** 19/11/2025  
**Problema:** Container Docker não consegue acessar PostgreSQL no IP externo `82.25.92.217:5432`  
**Status:** ✅ SOLUÇÃO IMPLEMENTADA

---

## 🔴 Problema Identificado

O banco de dados PostgreSQL está funcionando e acessível em outros sistemas, mas o container Docker do backend não consegue conectar.

**Sintomas:**
- ✅ Banco funciona em outros sistemas
- ✅ Host consegue acessar o banco
- ❌ Container Docker não consegue acessar `82.25.92.217:5432`
- ❌ Erro: `Connection timed out`

**Causa:**
- Containers Docker em rede bridge não conseguem acessar o IP externo do próprio host
- O IP `82.25.92.217` é o IP externo do servidor, mas dentro do Docker precisa usar `host.docker.internal` ou o IP do host na rede Docker

---

## ✅ Solução Implementada

### 1. **Adicionar `extra_hosts` no docker-compose.yml** ✅

Adicionado mapeamento `host.docker.internal:host-gateway` para permitir que containers acessem serviços do host:

```yaml
backend:
  extra_hosts:
    - "host.docker.internal:host-gateway"
  environment:
    - DATABASE_URL=postgresql://root:<redacted-legacy-password-encoded>@host.docker.internal:5432/dbrief
```

**O que isso faz:**
- ✅ Mapeia `host.docker.internal` para o gateway do host
- ✅ Permite que containers acessem serviços rodando no host
- ✅ Funciona em Linux, macOS e Windows

### 2. **Alterar DATABASE_URL para usar `host.docker.internal`** ✅

Mudado de:
```
DATABASE_URL=postgresql://root:<redacted-legacy-password-encoded>@82.25.92.217:5432/dbrief
```

Para:
```
DATABASE_URL=postgresql://root:<redacted-legacy-password-encoded>@host.docker.internal:5432/dbrief
```

---

## 🚀 Como Aplicar no Servidor

### Passo 1: Fazer Pull das Atualizações

```bash
ssh root@82.25.92.217
cd ~/debrief
git pull
```

### Passo 2: Testar Conexão do Container

```bash
# Testar se container consegue acessar o banco
./testar-conexao-docker.sh
```

Este script irá:
- ✅ Verificar se host consegue acessar o banco
- ✅ Verificar se container consegue acessar o banco
- ✅ Testar diferentes métodos de conexão
- ✅ Fornecer recomendações

### Passo 3: Rebuild do Backend

```bash
# Rebuild com nova configuração
docker-compose build --no-cache backend
docker-compose up -d backend

# Verificar logs
docker-compose logs backend | tail -50
```

### Passo 4: Verificar Conexão

```bash
# Verificar se backend consegue conectar
docker-compose exec backend python3 << EOF
import psycopg2
conn = psycopg2.connect(
    host="host.docker.internal",
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

## 🔧 Alternativas (Se `host.docker.internal` Não Funcionar)

### Alternativa 1: Usar IP do Host

```bash
# Descobrir IP do host na rede Docker
HOST_IP=$(hostname -I | awk '{print $1}')
echo "IP do host: $HOST_IP"

# Atualizar docker-compose.yml
# DATABASE_URL=postgresql://root:<redacted-legacy-password-encoded>@$HOST_IP:5432/dbrief
```

### Alternativa 2: Usar `network_mode: host`

```yaml
backend:
  network_mode: host  # Container usa rede do host diretamente
  environment:
    - DATABASE_URL=postgresql://root:<redacted-legacy-password-encoded>@82.25.92.217:5432/dbrief
```

**Nota:** Com `network_mode: host`, não precisa mapear portas e o container acessa a rede do host diretamente.

### Alternativa 3: Usar Gateway Docker

```bash
# Descobrir gateway Docker
DOCKER_GATEWAY=$(docker network inspect debrief_debrief-network | grep Gateway | head -1 | awk '{print $2}' | tr -d '"' | tr -d ',')

# Usar gateway em vez de IP externo
# DATABASE_URL=postgresql://root:<redacted-legacy-password-encoded>@$DOCKER_GATEWAY:5432/dbrief
```

---

## 📊 Verificações

### Verificar se `host.docker.internal` está funcionando

```bash
# Do container
docker-compose exec backend ping -c 2 host.docker.internal

# Testar conexão TCP
docker-compose exec backend timeout 5 bash -c "echo > /dev/tcp/host.docker.internal/5432" && echo "✅ Porta acessível" || echo "❌ Porta não acessível"
```

### Verificar logs do backend

```bash
# Ver logs completos
docker-compose logs backend

# Ver apenas erros
docker-compose logs backend | grep -i "error\|timeout\|connection"

# Ver se banco foi inicializado
docker-compose logs backend | grep -i "banco\|database\|inicializado"
```

### Verificar status do backend

```bash
# Status do container
docker-compose ps backend

# Health check
docker inspect debrief-backend --format='{{.State.Health.Status}}'
```

---

## ✅ Checklist de Resolução

- [ ] Pull das atualizações: `git pull`
- [ ] Teste de conexão: `./testar-conexao-docker.sh`
- [ ] Rebuild do backend: `docker-compose build --no-cache backend`
- [ ] Backend iniciado: `docker-compose up -d backend`
- [ ] Backend healthy: `docker-compose ps backend`
- [ ] Logs sem erros: `docker-compose logs backend | grep -i error`
- [ ] Conexão testada: `docker-compose exec backend python3 -c "import psycopg2; conn = psycopg2.connect(...)"`

---

## 🎯 Resultado Esperado

Após aplicar a correção:

1. **Container consegue acessar o banco:**
   ```bash
   docker-compose exec backend timeout 5 bash -c "echo > /dev/tcp/host.docker.internal/5432"
   # ✅ Porta acessível
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

## 📝 Arquivos Modificados

- ✅ `docker-compose.yml` - Adicionado `extra_hosts` e alterado `DATABASE_URL`
- ✅ `testar-conexao-docker.sh` - Script de diagnóstico de rede Docker
- ✅ `SOLUCAO_REDE_DOCKER_BANCO.md` - Documentação completa

---

## 🔍 Diagnóstico Rápido

Se ainda não funcionar, execute:

```bash
# 1. Verificar se host.docker.internal está mapeado
docker-compose exec backend cat /etc/hosts | grep host.docker.internal

# 2. Testar ping
docker-compose exec backend ping -c 2 host.docker.internal

# 3. Testar conexão TCP
docker-compose exec backend timeout 5 bash -c "echo > /dev/tcp/host.docker.internal/5432"

# 4. Testar conexão Python
docker-compose exec backend python3 << EOF
import psycopg2
try:
    conn = psycopg2.connect(
        host="host.docker.internal",
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

**✅ Solução implementada!**

**🔧 Execute `git pull` e `docker-compose build --no-cache backend` no servidor!**

