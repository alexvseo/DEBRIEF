#!/bin/bash

# Script para testar rotas de configurações e identificar duplicação de /api

echo "🧪 Testando rotas de configurações"
echo ""

# Obter token (se disponível)
TOKEN=""
if [ -f "/tmp/debrief_token.txt" ]; then
    TOKEN=$(cat /tmp/debrief_token.txt)
fi

echo "1️⃣  Testando rota diretamente no backend (porta 8000)..."
echo "   GET http://localhost:8000/api/configuracoes/agrupadas"
if [ -n "$TOKEN" ]; then
    RESPONSE=$(curl -s -w "\nHTTP_CODE:%{http_code}" -H "Authorization: Bearer $TOKEN" http://localhost:8000/api/configuracoes/agrupadas)
else
    RESPONSE=$(curl -s -w "\nHTTP_CODE:%{http_code}" http://localhost:8000/api/configuracoes/agrupadas)
fi
HTTP_CODE=$(echo "$RESPONSE" | grep "HTTP_CODE" | cut -d: -f2)
BODY=$(echo "$RESPONSE" | sed '/HTTP_CODE/d')
echo "   Status: $HTTP_CODE"
if [ "$HTTP_CODE" = "200" ]; then
    echo "   ✅ Rota funciona diretamente no backend"
else
    echo "   ❌ Rota NÃO funciona diretamente no backend"
    echo "   Resposta: $BODY" | head -5
fi
echo ""

echo "2️⃣  Testando rota via Caddy (porta 2022)..."
echo "   GET http://localhost:2022/api/configuracoes/agrupadas"
if [ -n "$TOKEN" ]; then
    RESPONSE=$(curl -s -w "\nHTTP_CODE:%{http_code}" -H "Authorization: Bearer $TOKEN" http://localhost:2022/api/configuracoes/agrupadas)
else
    RESPONSE=$(curl -s -w "\nHTTP_CODE:%{http_code}" http://localhost:2022/api/configuracoes/agrupadas)
fi
HTTP_CODE=$(echo "$RESPONSE" | grep "HTTP_CODE" | cut -d: -f2)
BODY=$(echo "$RESPONSE" | sed '/HTTP_CODE/d')
echo "   Status: $HTTP_CODE"
if [ "$HTTP_CODE" = "200" ]; then
    echo "   ✅ Rota funciona via Caddy"
else
    echo "   ❌ Rota NÃO funciona via Caddy"
    echo "   Resposta: $BODY" | head -5
fi
echo ""

echo "3️⃣  Verificando logs do backend (últimas 10 linhas com 'configuracoes')..."
echo ""
docker-compose logs backend | grep -i "configuracoes" | tail -10 || echo "   Nenhum log encontrado"
echo ""

echo "4️⃣  Verificando logs do Caddy (últimas 10 linhas com 'api')..."
echo ""
docker-compose logs caddy | grep -i "api" | tail -10 || echo "   Nenhum log encontrado"
echo ""

echo "5️⃣  Listando rotas do FastAPI relacionadas a configurações..."
echo ""
docker-compose exec backend python -c "
from app.main import app

routes = []
for route in app.routes:
    if hasattr(route, 'path') and hasattr(route, 'methods'):
        path = route.path
        methods = list(route.methods) if hasattr(route.methods, '__iter__') else [str(route.methods)]
        if 'configuracao' in path.lower():
            routes.append((path, methods))

print('   Rotas encontradas:')
for path, methods in sorted(routes):
    print(f'     {methods[0] if methods else \"GET\"} {path}')
" 2>&1 | grep -v "WARNING\|INFO" || echo "   ❌ Erro ao listar rotas"
echo ""

echo "✅ Teste concluído"
echo ""
echo "💡 Se a rota funciona diretamente no backend mas não via Caddy,"
echo "   o problema está na configuração do Caddyfile"

