# ⚡ Solução Rápida para Erros no Servidor

## 🔴 Problema Atual

1. **Backend não consegue conectar ao PostgreSQL** (localhost:5432)
2. **Frontend unhealthy** (pode ser temporário)

## ✅ Solução Rápida (Copiar e Colar)

```bash
cd /root/debrief
git pull origin main
./scripts/correcao/usar-host-network.sh
```

## 📋 Passo a Passo Manual

### 1. Parar containers atuais

```bash
cd /root/debrief
docker-compose down
```

### 2. Usar docker-compose.host-network.yml

```bash
docker-compose -f docker-compose.host-network.yml build --no-cache
docker-compose -f docker-compose.host-network.yml up -d
```

### 3. Verificar status

```bash
docker-compose -f docker-compose.host-network.yml ps
```

### 4. Verificar logs

```bash
docker-compose -f docker-compose.host-network.yml logs backend | tail -20
```

## 🔍 Verificar se Funcionou

### Testar conexão PostgreSQL do container

```bash
docker exec debrief-backend python3 << 'EOF'
import psycopg2
try:
    conn = psycopg2.connect(
        host='localhost', port=5432,
        user='postgres', password='Mslestra@2025',
        database='dbrief'
    )
    print("✅ Conexão OK!")
    conn.close()
except Exception as e:
    print(f"❌ Erro: {e}")
EOF
```

### Verificar network_mode

```bash
docker inspect debrief-backend --format='{{.HostConfig.NetworkMode}}'
```

**Deve retornar:** `host`

## ⚠️ Se Ainda Não Funcionar

### 1. Verificar PostgreSQL

```bash
./scripts/diagnostico/verificar-postgresql-servidor.sh
```

### 2. Corrigir PostgreSQL

```bash
./scripts/correcao/corrigir-postgresql-servidor.sh
```

### 3. Reiniciar backend

```bash
docker-compose -f docker-compose.host-network.yml restart backend
```

---

**💡 Dica:** Sempre use `docker-compose.host-network.yml` no servidor para garantir acesso ao PostgreSQL local.

