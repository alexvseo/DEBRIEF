# 🚀 Aplicar network_mode: host Completo - AGORA

## ✅ Problema

O Caddy não consegue acessar o backend porque está em uma rede Docker separada. Mesmo usando `127.0.0.1:8000`, o Caddy não consegue alcançar o `localhost` do host.

## ✅ Solução

Colocar **Caddy** e **Frontend** também em `network_mode: host`, assim como o backend.

## 🚀 Aplicar no Servidor

Execute no servidor:

```bash
ssh root@82.25.92.217
cd /root/debrief

# 1. Atualizar código
git pull

# 2. Verificar mudanças
grep "network_mode: host" docker-compose.yml
# Deve mostrar 3 serviços: backend, frontend, caddy

# 3. Verificar Caddyfile
grep ":2022" Caddyfile
# Deve mostrar: :2022 {

# 4. Parar todos os serviços
docker-compose stop

# 5. Remover containers
docker-compose rm -f

# 6. Recriar todos os serviços
docker-compose up -d

# 7. Aguardar inicialização
sleep 30

# 8. Verificar status
docker-compose ps

# 9. Testar login via Caddy (porta 2022)
curl -X POST http://localhost:2022/api/auth/login \
  -H "Content-Type: application/x-www-form-urlencoded" \
  -d "username=admin&password=admin123"

# 10. Testar login via Caddy externo
curl -X POST http://82.25.92.217:2022/api/auth/login \
  -H "Content-Type: application/x-www-form-urlencoded" \
  -d "username=admin&password=admin123"

# 11. Testar acesso ao frontend
curl -I http://localhost:2022/
curl -I http://82.25.92.217:2022/
```

## ✅ Resultado Esperado

1. **Login via Caddy:**
   ```json
   {
     "access_token": "eyJ...",
     "token_type": "bearer",
     "user": {...}
   }
   ```

2. **Frontend acessível:**
   - HTTP 200 OK
   - HTML da aplicação React

## 🔍 Verificar se Funcionou

### Status dos containers:
```bash
docker-compose ps
```
Todos devem estar "Up" e healthy.

### Logs do Caddy:
```bash
docker-compose logs caddy | tail -20
```
Não deve ter erros de conexão.

### Logs do Backend:
```bash
docker-compose logs backend | tail -20
```
Deve mostrar requisições sendo processadas.

### Logs do Frontend:
```bash
docker-compose logs frontend | tail -20
```
Deve mostrar requisições sendo processadas.

## 🔧 Portas em network_mode: host

Com `network_mode: host`, os serviços escutam diretamente nas portas do host:

- **Backend:** `localhost:8000` (ou `0.0.0.0:8000`)
- **Frontend:** `localhost:80` (ou `0.0.0.0:80`)
- **Caddy:** `localhost:2022` (ou `0.0.0.0:2022`)

## ⚠️ Importante

Com `network_mode: host`, não é possível mapear portas (`ports:` é ignorado). Os serviços devem escutar diretamente nas portas desejadas.

## 🔍 Se Ainda Não Funcionar

### Verificar se portas estão em uso:
```bash
netstat -tlnp | grep -E "8000|80|2022"
```

### Verificar logs completos:
```bash
docker-compose logs | tail -50
```

### Verificar se serviços estão rodando:
```bash
docker ps | grep debrief
```

