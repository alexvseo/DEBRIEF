# 🔧 Resolver Problema de Login Local

## Problema
O login local não funciona porque o backend não consegue conectar ao banco de dados remoto.

## Solução

### 1. Iniciar Túnel SSH

O túnel SSH precisa estar ativo para o backend acessar o banco remoto via `localhost:5432`.

**Execute manualmente:**
```bash
./scripts/dev/iniciar-tunel-ssh.sh
```

**OU execute diretamente:**
```bash
ssh -f -N -L 5432:localhost:5432 root@82.25.92.217
```

Você será solicitado a digitar a senha SSH do servidor.

### 2. Verificar se o Túnel está Ativo

```bash
lsof -i :5432 | grep ssh
```

Se aparecer um processo SSH, o túnel está ativo.

### 3. Reiniciar o Backend

```bash
docker-compose -f docker-compose.dev.yml restart backend
```

### 4. Verificar Logs

```bash
docker-compose -f docker-compose.dev.yml logs backend | tail -20
```

Procure por mensagens de sucesso na conexão com o banco.

### 5. Testar Login

```bash
curl -X POST http://localhost:8000/api/auth/login \
  -H "Content-Type: application/x-www-form-urlencoded" \
  -d "username=admin&password=admin123"
```

## Problemas Comuns

### PostgreSQL Local na Porta 5432

Se você tiver PostgreSQL local rodando na porta 5432, pare-o primeiro:

```bash
# Verificar processos
lsof -i :5432

# Parar PostgreSQL (macOS)
brew services stop postgresql

# OU matar processo específico
kill <PID>
```

### Túnel SSH Não Conecta

1. Verifique se você tem acesso SSH ao servidor:
   ```bash
   ssh root@82.25.92.217
   ```

2. Se usar chave SSH, certifique-se de que está configurada:
   ```bash
   ssh-add ~/.ssh/id_rsa
   ```

3. Se precisar usar senha, o script pedirá interativamente.

## Configuração Atual

- **Backend**: `network_mode: host` (acessa localhost diretamente)
- **DATABASE_URL**: `postgresql://postgres:<redacted-legacy-password-encoded>@localhost:5432/dbrief`
- **Túnel SSH**: `localhost:5432` → `82.25.92.217:5432`

## Próximos Passos

Após iniciar o túnel SSH e reiniciar o backend:

1. Acesse: http://localhost:5173
2. Faça login com:
   - **Username**: `admin`
   - **Password**: `admin123`

Se ainda não funcionar, verifique os logs do backend para erros específicos.

