#!/bin/bash

# Script para diagnosticar erro 404 em /api/configuracoes/agrupadas
# Verifica se há duplicação de prefixo /api

echo "🔍 Diagnosticando erro 404 em /api/configuracoes/agrupadas"
echo ""

echo "1️⃣  Verificando logs do backend (últimas 50 linhas)..."
echo ""
docker-compose logs backend | tail -50 | grep -E "404|configuracoes|/api" || echo "Nenhum log relevante encontrado"
echo ""

echo "2️⃣  Testando rota diretamente no backend (porta 8000)..."
echo ""
curl -s -o /dev/null -w "Status: %{http_code}\n" http://localhost:8000/api/configuracoes/agrupadas || echo "❌ Erro ao conectar"
echo ""

echo "3️⃣  Testando rota via Caddy (porta 2022)..."
echo ""
curl -s -o /dev/null -w "Status: %{http_code}\n" http://localhost:2022/api/configuracoes/agrupadas || echo "❌ Erro ao conectar"
echo ""

echo "4️⃣  Verificando rotas registradas no FastAPI..."
echo ""
docker-compose exec backend python -c "
from app.main import app
import json

routes = []
for route in app.routes:
    if hasattr(route, 'path') and hasattr(route, 'methods'):
        routes.append({
            'path': route.path,
            'methods': list(route.methods)
        })

# Filtrar rotas relacionadas a configuracoes
config_routes = [r for r in routes if 'configuracao' in r['path'].lower()]
for route in config_routes:
    print(f\"  {route['methods']} {route['path']}\")
" 2>&1 || echo "❌ Erro ao listar rotas"
echo ""

echo "5️⃣  Verificando Caddyfile..."
echo ""
if [ -f "Caddyfile" ]; then
    echo "✅ Caddyfile encontrado"
    grep -A 10 "path /api" Caddyfile || echo "Nenhuma configuração /api encontrada"
else
    echo "❌ Caddyfile não encontrado"
fi
echo ""

echo "6️⃣  Testando com curl detalhado (via Caddy)..."
echo ""
curl -v http://localhost:2022/api/configuracoes/agrupadas 2>&1 | grep -E "HTTP|Location|Host|< " | head -20
echo ""

echo "✅ Diagnóstico concluído"
echo ""
echo "💡 Se o status for 404, verifique:"
echo "   1. Se a rota está registrada no FastAPI"
echo "   2. Se o Caddyfile está fazendo proxy corretamente"
echo "   3. Se há duplicação de prefixo /api em algum lugar"

