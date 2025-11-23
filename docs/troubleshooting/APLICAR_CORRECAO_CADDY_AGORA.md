# 🔧 Aplicar Correção do Caddy - AGORA

## ❌ Problema

Caddy não está respondendo corretamente. O Caddyfile estava configurado para escutar na porta `:2022`, mas dentro do container deve escutar na porta `:80`.

## ✅ Correção

Execute no servidor:

```bash
ssh root@82.25.92.217
cd /root/debrief

# 1. Atualizar código
git pull

# 2. Verificar Caddyfile (deve mostrar :80, não :2022)
head -5 Caddyfile

# 3. Reiniciar Caddy
docker-compose restart caddy

# 4. Aguardar
sleep 10

# 5. Testar localmente
curl http://localhost:2022

# 6. Ver logs
docker-compose logs --tail=20 caddy
```

## 🧪 Teste Completo

Execute o script de teste:

```bash
./scripts/deploy/testar-acesso-completo.sh
```

Ou manualmente:

```bash
# No servidor:
cd /root/debrief

# Testar Backend
curl http://localhost:2025/health

# Testar Frontend via Caddy
curl http://localhost:2022

# Testar API via Caddy
curl http://localhost:2022/api/health
```

## 📋 O Que Foi Corrigido

**Antes:**
```caddy
:2022 {  # ❌ Porta errada dentro do container
```

**Depois:**
```caddy
:80 {  # ✅ Porta correta (mapeada para 2022 externamente)
```

## ✅ Verificar se Funcionou

1. **No servidor (localmente):**
   ```bash
   curl http://localhost:2022
   ```
   Deve retornar HTML do frontend.

2. **Do seu computador:**
   - Acesse: http://82.25.92.217:2022
   - Deve carregar a página de login.

## 🔍 Se Ainda Não Funcionar

Execute diagnóstico completo:

```bash
./scripts/deploy/diagnosticar-servidor.sh
```

Isso mostrará exatamente onde está o problema.

