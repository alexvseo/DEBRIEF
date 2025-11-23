# 🔐 Testar Login - AGORA

## ✅ Status Atual

- ✅ Backend conectado ao banco de dados
- ✅ Container backend rodando e healthy
- ⚠️ Login precisa ser testado na porta correta

## 🔍 Problema

Com `network_mode: host`, o backend está rodando diretamente na porta **8000** do host, não na porta 2025.

## 🚀 Testar Login no Servidor

Execute no servidor:

```bash
ssh root@82.25.92.217
cd /root/debrief

# 1. Testar login diretamente no backend (porta 8000)
echo "Testando login diretamente no backend..."
curl -X POST http://localhost:8000/api/auth/login \
  -H "Content-Type: application/x-www-form-urlencoded" \
  -d "username=admin&password=admin123"

# 2. Testar login via Caddy (porta 2022)
echo ""
echo "Testando login via Caddy..."
curl -X POST http://localhost:2022/api/auth/login \
  -H "Content-Type: application/x-www-form-urlencoded" \
  -d "username=admin&password=admin123"

# 3. Testar acesso externo (se funcionar)
echo ""
echo "Testando acesso externo..."
curl -X POST http://82.25.92.217:2022/api/auth/login \
  -H "Content-Type: application/x-www-form-urlencoded" \
  -d "username=admin&password=admin123"
```

## ✅ Resultado Esperado

Deve retornar JSON com:
```json
{
  "access_token": "eyJ...",
  "token_type": "bearer"
}
```

## 🔍 Se Não Funcionar

### Verificar logs do backend:
```bash
docker-compose logs backend | tail -30
```

### Verificar logs do Caddy:
```bash
docker-compose logs caddy | tail -30
```

### Verificar se backend está escutando:
```bash
netstat -tlnp | grep 8000
# Deve mostrar: tcp 0.0.0.0:8000 LISTEN
```

### Verificar se Caddy está escutando:
```bash
netstat -tlnp | grep 2022
# Deve mostrar: tcp 0.0.0.0:2022 LISTEN
```

### Verificar configuração do Caddy:
```bash
cat Caddyfile | grep -A 5 "reverse_proxy"
# Deve mostrar: reverse_proxy localhost:8000
```

## 🔧 Se Caddy Não Estiver Funcionando

```bash
# Reiniciar Caddy
docker-compose restart caddy

# Verificar status
docker-compose ps caddy

# Ver logs
docker-compose logs caddy | tail -50
```

