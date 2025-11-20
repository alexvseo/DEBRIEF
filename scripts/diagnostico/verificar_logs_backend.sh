#!/bin/bash

# Script para verificar logs do backend e identificar erros
# Execute no servidor: ./verificar_logs_backend.sh

echo "=========================================="
echo "🔍 VERIFICANDO LOGS DO BACKEND"
echo "=========================================="
echo ""

# Cores
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

# 1. Status do container
echo "1️⃣  Status do container backend..."
echo "----------------------------------------"
docker-compose ps backend
echo ""

# 2. Últimas 100 linhas dos logs
echo "2️⃣  Últimas 100 linhas dos logs..."
echo "----------------------------------------"
docker-compose logs --tail=100 backend
echo ""

# 3. Procurar erros específicos
echo "3️⃣  Erros encontrados nos logs..."
echo "----------------------------------------"
ERRORS=$(docker-compose logs backend 2>&1 | grep -i "error\|exception\|traceback\|failed\|fatal" | tail -20)
if [ -n "$ERRORS" ]; then
    echo -e "${RED}❌ Erros encontrados:${NC}"
    echo "$ERRORS"
else
    echo -e "${GREEN}✅ Nenhum erro encontrado nos logs recentes${NC}"
fi
echo ""

# 4. Verificar se processo está rodando
echo "4️⃣  Processos dentro do container..."
echo "----------------------------------------"
docker-compose exec -T backend ps aux 2>/dev/null | grep -E "uvicorn|python" || echo "❌ Container não está rodando ou não consegue executar comandos"
echo ""

# 5. Testar health check
echo "5️⃣  Testando health check..."
echo "----------------------------------------"
docker-compose exec -T backend curl -s http://localhost:8000/health 2>/dev/null || echo "❌ Health check falhou"
echo ""

# 6. Verificar variáveis de ambiente críticas
echo "6️⃣  Variáveis de ambiente críticas..."
echo "----------------------------------------"
docker-compose exec -T backend env 2>/dev/null | grep -E "DATABASE_URL|ALLOWED_EXTENSIONS|SECRET_KEY" | head -3 || echo "❌ Não foi possível verificar variáveis"
echo ""

echo "=========================================="
echo "✅ Verificação concluída!"
echo "=========================================="
echo ""
echo "📝 Próximos passos:"
echo "   1. Analise os erros acima"
echo "   2. Se houver erro de ALLOWED_EXTENSIONS: já foi corrigido, faça rebuild"
echo "   3. Se houver erro de banco: verifique DATABASE_URL"
echo "   4. Se houver erro de importação: verifique requirements.txt"
echo ""

