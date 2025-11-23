# 🔧 Corrigir Erro 404 em /api/configuracoes/agrupadas

## ❌ Problema
O backend está recebendo `/api/api/configuracoes/agrupadas` (prefixo `/api` duplicado) e retornando 404.

## ✅ Solução

### Passo 1: No servidor, executar diagnóstico
```bash
cd ~/debrief
./scripts/deploy/diagnosticar-404-configuracoes.sh
```

### Passo 2: Verificar logs do backend
```bash
docker-compose logs backend | tail -30 | grep -E "404|configuracoes"
```

### Passo 3: Testar rota diretamente no backend
```bash
# Testar diretamente no backend (porta 8000)
curl -H "Authorization: Bearer SEU_TOKEN" http://localhost:8000/api/configuracoes/agrupadas

# Testar via Caddy (porta 2022)
curl -H "Authorization: Bearer SEU_TOKEN" http://localhost:2022/api/configuracoes/agrupadas
```

### Passo 4: Se o problema persistir, verificar Caddyfile
```bash
cat Caddyfile | grep -A 10 "path /api"
```

### Passo 5: Reiniciar Caddy
```bash
docker-compose restart caddy
docker-compose logs caddy | tail -20
```

## 🔍 Possíveis Causas

1. **Caddy adicionando prefixo extra:** O Caddyfile pode estar configurado para adicionar `/api` ao fazer proxy
2. **Frontend fazendo requisição duplicada:** O frontend pode estar fazendo requisição com `/api/api/...`
3. **Backend recebendo URL incorreta:** O backend pode estar recebendo a URL com prefixo duplicado

## 💡 Verificação Rápida

Execute no servidor:
```bash
# Verificar rotas do FastAPI
docker-compose exec backend python -c "
from app.main import app
for route in app.routes:
    if hasattr(route, 'path') and 'configuracao' in route.path.lower():
        print(f'{route.path}')
"
```

Se a rota `/api/configuracoes/agrupadas` aparecer na lista, o problema está no Caddy ou no frontend.

