# 🔧 Solução: Erro de Conexão PostgreSQL no Container

## ❌ Problema

O backend não consegue conectar ao PostgreSQL mesmo após configurar o banco:

```
connection to server at "localhost" (::1), port 5432 failed: Connection refused
connection to server at "localhost" (127.0.0.1), port 5432 failed: Connection refused
```

## 🔍 Causa

O container Docker não está em `network_mode: host`, então não consegue acessar `localhost:5432` do host.

## ✅ Solução

### Opção 1: Usar docker-compose.host-network.yml (Recomendado)

```bash
# 1. Parar containers atuais
docker-compose down

# 2. Usar docker-compose.host-network.yml
docker-compose -f docker-compose.host-network.yml up -d

# 3. Verificar status
docker-compose -f docker-compose.host-network.yml ps
```

### Opção 2: Script Automatizado

```bash
./scripts/correcao/corrigir-rede-container.sh
```

Este script:
- ✅ Para containers atuais
- ✅ Usa `docker-compose.host-network.yml`
- ✅ Reconstrui containers
- ✅ Testa conexão

### Opção 3: Diagnóstico Primeiro

```bash
# 1. Diagnosticar o problema
./scripts/diagnostico/diagnosticar-rede-container.sh

# 2. Corrigir
./scripts/correcao/corrigir-rede-container.sh

# 3. Verificar logs
docker-compose logs backend
```

## 🔍 Verificação

### 1. Verificar network_mode

```bash
docker inspect debrief-backend --format='{{.HostConfig.NetworkMode}}'
```

Deve retornar: `host`

### 2. Testar conexão do container

```bash
docker exec debrief-backend python3 << 'EOF'
import psycopg2
try:
    conn = psycopg2.connect(
        host='localhost',
        port=5432,
        user='postgres',
        password='Mslestra@2025',
        database='dbrief'
    )
    print("✅ Conexão funcionou!")
    conn.close()
except Exception as e:
    print(f"❌ Erro: {e}")
EOF
```

### 3. Verificar logs do backend

```bash
docker-compose logs backend | grep -i "banco\|database\|postgres"
```

Deve aparecer:
```
✅ Banco de dados inicializado e tabelas criadas
```

## 📋 Checklist de Solução

- [ ] PostgreSQL está rodando: `sudo systemctl status postgresql`
- [ ] PostgreSQL está escutando em localhost: `netstat -tlnp | grep 5432`
- [ ] Container está em `network_mode: host`
- [ ] DATABASE_URL está correto: `postgresql://postgres:...@localhost:5432/dbrief`
- [ ] Container foi reiniciado após mudanças

## 🚀 Solução Rápida (Copiar e Colar)

```bash
cd /root/debrief
git pull origin main
docker-compose down
docker-compose -f docker-compose.host-network.yml up -d
sleep 5
docker-compose logs backend | tail -20
```

## ⚠️ Notas Importantes

1. **Sempre use `docker-compose.host-network.yml` no servidor** para garantir `network_mode: host`

2. **Após mudanças no PostgreSQL**, sempre reinicie o container:
   ```bash
   docker-compose restart backend
   ```

3. **Se usar `docker-compose.yml` padrão**, o container não terá acesso a `localhost:5432`

4. **Verificar qual arquivo está sendo usado**:
   ```bash
   docker inspect debrief-backend | grep -A 5 "NetworkMode"
   ```

## 🔗 Scripts Disponíveis

- `./scripts/diagnostico/diagnosticar-rede-container.sh` - Diagnóstico completo
- `./scripts/correcao/corrigir-rede-container.sh` - Correção automática
- `./scripts/diagnostico/verificar-postgresql-servidor.sh` - Verificar PostgreSQL
- `./scripts/correcao/corrigir-postgresql-servidor.sh` - Corrigir PostgreSQL

---

**Última atualização:** 2025-01-20

