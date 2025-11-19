#!/bin/bash

# Script de Diagnóstico - Backend Unhealthy
# Execute no servidor para diagnosticar problemas do backend

echo "=========================================="
echo "🔍 DIAGNÓSTICO BACKEND UNHEALTHY - DeBrief"
echo "=========================================="
echo ""

# Cores
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# 1. Verificar status do container
echo "1️⃣  Verificando status do container backend..."
echo "----------------------------------------"
docker-compose ps backend
echo ""

# 2. Verificar health status
echo "2️⃣  Verificando health status..."
echo "----------------------------------------"
HEALTH_STATUS=$(docker inspect debrief-backend --format='{{.State.Health.Status}}' 2>/dev/null || echo "not_found")
if [ "$HEALTH_STATUS" = "healthy" ]; then
    echo -e "${GREEN}✅ Backend está healthy${NC}"
elif [ "$HEALTH_STATUS" = "unhealthy" ]; then
    echo -e "${RED}❌ Backend está unhealthy${NC}"
    
    # Mostrar últimas tentativas de health check
    echo ""
    echo "   Últimas tentativas de health check:"
    docker inspect debrief-backend --format='{{range .State.Health.Log}}{{.Output}}{{end}}' 2>/dev/null | tail -3
elif [ "$HEALTH_STATUS" = "starting" ]; then
    echo -e "${YELLOW}⚠️  Backend ainda está iniciando...${NC}"
else
    echo -e "${YELLOW}⚠️  Status: $HEALTH_STATUS${NC}"
fi
echo ""

# 3. Ver logs completos do backend
echo "3️⃣  Últimas 50 linhas dos logs do backend..."
echo "----------------------------------------"
docker-compose logs --tail=50 backend
echo ""

# 4. Verificar erros específicos
echo "4️⃣  Procurando erros nos logs..."
echo "----------------------------------------"
ERRORS=$(docker-compose logs backend 2>&1 | grep -i "error\|exception\|traceback\|failed\|fatal" | tail -10)
if [ -n "$ERRORS" ]; then
    echo -e "${RED}❌ Erros encontrados:${NC}"
    echo "$ERRORS"
else
    echo -e "${GREEN}✅ Nenhum erro encontrado nos logs recentes${NC}"
fi
echo ""

# 5. Testar health check manualmente
echo "5️⃣  Testando health check manualmente..."
echo "----------------------------------------"
HEALTH_TEST=$(docker-compose exec -T backend curl -s -o /dev/null -w "%{http_code}" http://localhost:8000/health 2>/dev/null || echo "000")
if [ "$HEALTH_TEST" = "200" ]; then
    echo -e "${GREEN}✅ Health check retorna 200 OK${NC}"
    docker-compose exec -T backend curl -s http://localhost:8000/health | head -3
elif [ "$HEALTH_TEST" = "000" ]; then
    echo -e "${RED}❌ Health check falhou (não conseguiu conectar)${NC}"
    echo "   Possíveis causas:"
    echo "   - Backend não está rodando"
    echo "   - Backend não iniciou corretamente"
    echo "   - Erro ao iniciar a aplicação"
else
    echo -e "${YELLOW}⚠️  Health check retornou HTTP $HEALTH_TEST${NC}"
fi
echo ""

# 6. Verificar se o processo uvicorn está rodando
echo "6️⃣  Verificando processos dentro do container..."
echo "----------------------------------------"
PROCESSES=$(docker-compose exec -T backend ps aux 2>/dev/null | grep -E "uvicorn|python" || echo "Nenhum processo encontrado")
if echo "$PROCESSES" | grep -q "uvicorn"; then
    echo -e "${GREEN}✅ Processo uvicorn está rodando${NC}"
    echo "$PROCESSES" | head -3
else
    echo -e "${RED}❌ Processo uvicorn NÃO está rodando${NC}"
    echo "   Isso significa que o backend não iniciou corretamente"
fi
echo ""

# 7. Verificar variáveis de ambiente críticas
echo "7️⃣  Verificando variáveis de ambiente críticas..."
echo "----------------------------------------"
docker-compose exec -T backend env 2>/dev/null | grep -E "DATABASE_URL|SECRET_KEY|ENCRYPTION_KEY|ALLOWED_EXTENSIONS" | head -5 || echo "Não foi possível verificar variáveis"
echo ""

# 8. Testar conexão com banco de dados
echo "8️⃣  Testando conexão com banco de dados..."
echo "----------------------------------------"
DB_TEST=$(docker-compose exec -T backend python -c "
from app.core.database import engine
from sqlalchemy import text
try:
    with engine.connect() as conn:
        result = conn.execute(text('SELECT 1'))
        print('OK')
except Exception as e:
    print(f'ERRO: {e}')
" 2>/dev/null || echo "ERRO: Não foi possível testar")

if [ "$DB_TEST" = "OK" ]; then
    echo -e "${GREEN}✅ Conexão com banco de dados OK${NC}"
else
    echo -e "${RED}❌ Erro na conexão com banco:${NC}"
    echo "   $DB_TEST"
fi
echo ""

# 9. Verificar se há problemas de importação
echo "9️⃣  Testando importação dos módulos principais..."
echo "----------------------------------------"
IMPORT_TEST=$(docker-compose exec -T backend python -c "
try:
    from app.main import app
    from app.core.config import settings
    print('OK')
except Exception as e:
    print(f'ERRO: {e}')
" 2>/dev/null || echo "ERRO: Não foi possível testar")

if [ "$IMPORT_TEST" = "OK" ]; then
    echo -e "${GREEN}✅ Importação dos módulos OK${NC}"
else
    echo -e "${RED}❌ Erro na importação:${NC}"
    echo "   $IMPORT_TEST"
fi
echo ""

# 10. Verificar espaço em disco
echo "🔟 Verificando espaço em disco..."
echo "----------------------------------------"
df -h / | tail -1
echo ""

echo "=========================================="
echo "✅ Diagnóstico concluído!"
echo "=========================================="
echo ""
echo "📝 Próximos passos baseados no diagnóstico:"
echo ""
if [ "$HEALTH_STATUS" = "unhealthy" ]; then
    echo "   1. 🔴 PRIORIDADE: Backend está unhealthy"
    echo "      - Verifique os logs acima para identificar o erro"
    echo "      - Erros comuns:"
    echo "        * Erro de conexão com banco de dados"
    echo "        * Erro de configuração (ALLOWED_EXTENSIONS, etc)"
    echo "        * Erro de importação de módulos"
    echo "        * Falta de espaço em disco"
    echo ""
    echo "   2. Soluções sugeridas:"
    echo "      - docker-compose logs backend | tail -100"
    echo "      - docker-compose restart backend"
    echo "      - docker-compose build --no-cache backend"
    echo "      - docker-compose up -d backend"
fi
echo ""

