# 🔧 Corrigir Caddy IPv4 - AGORA

## ✅ Problema Identificado

- ✅ Login direto no backend (porta 8000) **funciona perfeitamente**
- ❌ Login via Caddy (porta 2022) **falha com erro 502**
- Erro: `dial tcp [::1]:8000: connect: connection refused`

## 🔍 Causa

O Caddy está tentando conectar via **IPv6** (`[::1]:8000`) e o backend está escutando apenas em **IPv4** (`0.0.0.0:8000`).

## ✅ Solução Aplicada

Alterado o `Caddyfile` para usar `127.0.0.1:8000` em vez de `localhost:8000`, forçando IPv4.

## 🚀 Aplicar no Servidor

Execute no servidor:

```bash
ssh root@82.25.92.217
cd /root/debrief

# 1. Atualizar código
git pull

# 2. Verificar mudança no Caddyfile
grep "127.0.0.1:8000" Caddyfile

# 3. Reiniciar Caddy para aplicar nova configuração
docker-compose restart caddy

# 4. Aguardar
sleep 5

# 5. Testar login via Caddy (porta 2022)
curl -X POST http://localhost:2022/api/auth/login \
  -H "Content-Type: application/x-www-form-urlencoded" \
  -d "username=admin&password=admin123"

# 6. Testar login via Caddy externo
curl -X POST http://82.25.92.217:2022/api/auth/login \
  -H "Content-Type: application/x-www-form-urlencoded" \
  -d "username=admin&password=admin123"
```

## ✅ Resultado Esperado

Deve retornar JSON com:
```json
{
  "access_token": "eyJ...",
  "token_type": "bearer",
  "user": {...}
}
```

## 🔍 Se Ainda Não Funcionar

### Verificar logs do Caddy:
```bash
docker-compose logs caddy | tail -20
```

### Verificar se backend está acessível:
```bash
# Do host
curl http://127.0.0.1:8000/health

# Do container Caddy (deve falhar se não estiver em network_mode: host)
docker exec debrief-caddy wget -O- http://127.0.0.1:8000/health 2>&1
```

### Se Caddy não conseguir acessar 127.0.0.1:8000:

O Caddy está em uma rede Docker separada e não consegue acessar o `127.0.0.1` do host. Nesse caso, precisamos colocar o Caddy também em `network_mode: host`.

## 🔧 Alternativa: Caddy em network_mode: host

Se a solução acima não funcionar, execute:

```bash
# Editar docker-compose.yml
nano docker-compose.yml

# Adicionar na seção caddy:
network_mode: host

# Remover:
# - ports: "2022:80"
# - networks: debrief-network

# Atualizar Caddyfile para escutar na porta 2022 diretamente:
# :2022 {
#   ...
# }

# Recriar Caddy
docker-compose stop caddy
docker-compose rm -f caddy
docker-compose up -d caddy
```

