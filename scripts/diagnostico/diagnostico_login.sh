#!/bin/bash

# Script de Diagnóstico - Erro de Login
# Execute no servidor para diagnosticar problemas

echo "=========================================="
echo "🔍 DIAGNÓSTICO DE LOGIN - DeBrief"
echo "=========================================="
echo ""

# Cores
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# 1. Verificar containers
echo "1️⃣  Verificando containers Docker..."
echo "----------------------------------------"
docker-compose ps
echo ""

# 2. Verificar se backend está rodando
echo "2️⃣  Verificando se backend está acessível..."
echo "----------------------------------------"
BACKEND_STATUS=$(curl -s -o /dev/null -w "%{http_code}" http://localhost:2025/health 2>/dev/null)
if [ "$BACKEND_STATUS" = "200" ]; then
    echo -e "${GREEN}✅ Backend está respondendo (HTTP $BACKEND_STATUS)${NC}"
    curl -s http://localhost:2025/health | jq . 2>/dev/null || curl -s http://localhost:2025/health
else
    echo -e "${RED}❌ Backend não está respondendo (HTTP $BACKEND_STATUS)${NC}"
    echo "   Verifique os logs: docker-compose logs backend"
fi
echo ""

# 3. Verificar se frontend está acessível
echo "3️⃣  Verificando se frontend está acessível..."
echo "----------------------------------------"
FRONTEND_STATUS=$(curl -s -o /dev/null -w "%{http_code}" http://localhost:2022 2>/dev/null)
if [ "$FRONTEND_STATUS" = "200" ]; then
    echo -e "${GREEN}✅ Frontend está respondendo (HTTP $FRONTEND_STATUS)${NC}"
else
    echo -e "${RED}❌ Frontend não está respondendo (HTTP $FRONTEND_STATUS)${NC}"
    echo "   Verifique os logs: docker-compose logs frontend"
fi
echo ""

# 4. Testar proxy do nginx
echo "4️⃣  Testando proxy do nginx (/api -> backend)..."
echo "----------------------------------------"
PROXY_STATUS=$(curl -s -o /dev/null -w "%{http_code}" http://localhost:2022/api/health 2>/dev/null)
if [ "$PROXY_STATUS" = "200" ]; then
    echo -e "${GREEN}✅ Proxy do nginx está funcionando (HTTP $PROXY_STATUS)${NC}"
    curl -s http://localhost:2022/api/health | jq . 2>/dev/null || curl -s http://localhost:2022/api/health
else
    echo -e "${RED}❌ Proxy do nginx não está funcionando (HTTP $PROXY_STATUS)${NC}"
    echo "   Verifique a configuração do nginx.conf"
fi
echo ""

# 5. Testar endpoint de login diretamente
echo "5️⃣  Testando endpoint de login..."
echo "----------------------------------------"
LOGIN_RESPONSE=$(curl -s -X POST http://localhost:2025/api/auth/login \
    -H "Content-Type: application/x-www-form-urlencoded" \
    -d "username=admin&password=admin123" \
    -w "\nHTTP_CODE:%{http_code}")

HTTP_CODE=$(echo "$LOGIN_RESPONSE" | grep "HTTP_CODE" | cut -d: -f2)
BODY=$(echo "$LOGIN_RESPONSE" | grep -v "HTTP_CODE")

if [ "$HTTP_CODE" = "200" ]; then
    echo -e "${GREEN}✅ Login funcionando (HTTP $HTTP_CODE)${NC}"
    echo "$BODY" | jq . 2>/dev/null || echo "$BODY"
else
    echo -e "${RED}❌ Login falhou (HTTP $HTTP_CODE)${NC}"
    echo "Resposta: $BODY"
fi
echo ""

# 6. Testar endpoint de login via proxy
echo "6️⃣  Testando login via proxy nginx..."
echo "----------------------------------------"
PROXY_LOGIN_RESPONSE=$(curl -s -X POST http://localhost:2022/api/auth/login \
    -H "Content-Type: application/x-www-form-urlencoded" \
    -d "username=admin&password=admin123" \
    -w "\nHTTP_CODE:%{http_code}")

PROXY_HTTP_CODE=$(echo "$PROXY_LOGIN_RESPONSE" | grep "HTTP_CODE" | cut -d: -f2)
PROXY_BODY=$(echo "$PROXY_LOGIN_RESPONSE" | grep -v "HTTP_CODE")

if [ "$PROXY_HTTP_CODE" = "200" ]; then
    echo -e "${GREEN}✅ Login via proxy funcionando (HTTP $PROXY_HTTP_CODE)${NC}"
    echo "$PROXY_BODY" | jq . 2>/dev/null || echo "$PROXY_BODY"
else
    echo -e "${RED}❌ Login via proxy falhou (HTTP $PROXY_HTTP_CODE)${NC}"
    echo "Resposta: $PROXY_BODY"
fi
echo ""

# 7. Verificar logs do backend
echo "7️⃣  Últimas linhas dos logs do backend..."
echo "----------------------------------------"
docker-compose logs --tail=20 backend | tail -10
echo ""

# 8. Verificar logs do frontend
echo "8️⃣  Últimas linhas dos logs do frontend..."
echo "----------------------------------------"
docker-compose logs --tail=20 frontend | tail -10
echo ""

# 9. Verificar conexão com banco
echo "9️⃣  Verificando conexão com banco de dados..."
echo "----------------------------------------"
docker-compose exec -T backend python -c "
from app.core.database import engine
from sqlalchemy import text
try:
    with engine.connect() as conn:
        result = conn.execute(text('SELECT COUNT(*) FROM users'))
        count = result.fetchone()[0]
        print(f'✅ Banco conectado - {count} usuário(s) encontrado(s)')
except Exception as e:
    print(f'❌ Erro ao conectar ao banco: {e}')
" 2>/dev/null || echo "❌ Não foi possível verificar o banco"
echo ""

# 10. Verificar variáveis de ambiente
echo "🔟 Verificando variáveis de ambiente do backend..."
echo "----------------------------------------"
docker-compose exec -T backend env | grep -E "DATABASE_URL|FRONTEND_URL|CORS" | head -5
echo ""

echo "=========================================="
echo "✅ Diagnóstico concluído!"
echo "=========================================="
echo ""
echo "📝 Próximos passos:"
echo "   1. Se backend não está rodando: docker-compose up -d backend"
echo "   2. Se proxy não funciona: verificar nginx.conf"
echo "   3. Se login falha: verificar credenciais no banco"
echo "   4. Se CORS erro: verificar FRONTEND_URL no backend"
echo ""

