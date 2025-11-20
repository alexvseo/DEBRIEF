#!/bin/bash

################################################################################
# Script para testar acesso completo ao sistema
# Testa localmente e externamente
################################################################################

set -e

# Cores
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

print_info() {
    echo -e "${BLUE}ℹ️  $1${NC}"
}

print_success() {
    echo -e "${GREEN}✅ $1${NC}"
}

print_warning() {
    echo -e "${YELLOW}⚠️  $1${NC}"
}

print_error() {
    echo -e "${RED}❌ $1${NC}"
}

SERVER_HOST="82.25.92.217"
SERVER_USER="root"
PROJECT_DIR="/root/debrief"

echo "🧪 Teste Completo de Acesso ao Sistema"
echo "========================================"
echo ""

# Executar testes no servidor
ssh ${SERVER_USER}@${SERVER_HOST} << 'ENDSSH'
    set -e
    
    cd /root/debrief || { echo "❌ Diretório não encontrado"; exit 1; }
    
    echo "1️⃣  Testando Backend diretamente (porta 2025)..."
    echo ""
    BACKEND_DIRECT=$(curl -s -o /dev/null -w "%{http_code}" http://localhost:2025/health 2>&1 || echo "FAILED")
    if [ "$BACKEND_DIRECT" = "200" ]; then
        echo "✅ Backend responde diretamente (HTTP $BACKEND_DIRECT)"
        curl -s http://localhost:2025/health | head -1
    else
        echo "❌ Backend NÃO responde (Status: $BACKEND_DIRECT)"
    fi
    echo ""
    
    echo "2️⃣  Testando Frontend diretamente (porta 80 interna)..."
    echo ""
    FRONTEND_DIRECT=$(docker exec debrief-frontend wget -q -O- http://localhost:80 2>&1 | head -1 || echo "FAILED")
    if [ "$FRONTEND_DIRECT" != "FAILED" ] && [ -n "$FRONTEND_DIRECT" ]; then
        echo "✅ Frontend responde internamente"
        echo "   Primeira linha: ${FRONTEND_DIRECT:0:50}..."
    else
        echo "❌ Frontend NÃO responde internamente"
    fi
    echo ""
    
    echo "3️⃣  Testando se Caddy consegue acessar Backend..."
    echo ""
    CADDY_BACKEND=$(docker exec debrief-caddy wget -q -O- http://debrief-backend:8000/health 2>&1 || echo "FAILED")
    if [ "$CADDY_BACKEND" != "FAILED" ] && echo "$CADDY_BACKEND" | grep -q "healthy"; then
        echo "✅ Caddy consegue acessar Backend"
        echo "$CADDY_BACKEND"
    else
        echo "❌ Caddy NÃO consegue acessar Backend"
        echo "   Resposta: $CADDY_BACKEND"
    fi
    echo ""
    
    echo "4️⃣  Testando se Caddy consegue acessar Frontend..."
    echo ""
    CADDY_FRONTEND=$(docker exec debrief-caddy wget -q -O- http://debrief-frontend:80 2>&1 | head -1 || echo "FAILED")
    if [ "$CADDY_FRONTEND" != "FAILED" ] && [ -n "$CADDY_FRONTEND" ]; then
        echo "✅ Caddy consegue acessar Frontend"
        echo "   Primeira linha: ${CADDY_FRONTEND:0:50}..."
    else
        echo "❌ Caddy NÃO consegue acessar Frontend"
        echo "   Resposta: $CADDY_FRONTEND"
    fi
    echo ""
    
    echo "5️⃣  Testando Caddy localmente (porta 2022)..."
    echo ""
    CADDY_LOCAL=$(curl -s -o /dev/null -w "%{http_code}" http://localhost:2022 2>&1 || echo "FAILED")
    if [ "$CADDY_LOCAL" = "200" ] || [ "$CADDY_LOCAL" = "301" ] || [ "$CADDY_LOCAL" = "302" ]; then
        echo "✅ Caddy responde localmente (HTTP $CADDY_LOCAL)"
        curl -s http://localhost:2022 | head -10
    else
        echo "❌ Caddy NÃO responde localmente (Status: $CADDY_LOCAL)"
    fi
    echo ""
    
    echo "6️⃣  Testando API via Caddy..."
    echo ""
    API_CADDY=$(curl -s -o /dev/null -w "%{http_code}" http://localhost:2022/api/health 2>&1 || echo "FAILED")
    if [ "$API_CADDY" = "200" ]; then
        echo "✅ API via Caddy responde (HTTP $API_CADDY)"
        curl -s http://localhost:2022/api/health | head -1
    else
        echo "❌ API via Caddy NÃO responde (Status: $API_CADDY)"
    fi
    echo ""
    
    echo "7️⃣  Verificando logs do Caddy (últimas 30 linhas com erros)..."
    echo ""
    docker-compose logs --tail=30 caddy | grep -iE "error|fail|502|503|timeout|refused" || echo "   Nenhum erro encontrado nos logs recentes"
    echo ""
    
    echo "8️⃣  Verificando rede Docker..."
    echo ""
    docker network inspect debrief-network --format '{{range .Containers}}{{.Name}} {{end}}' 2>/dev/null || echo "⚠️  Rede não encontrada"
    echo ""
    
    echo "9️⃣  Verificando se portas estão escutando..."
    echo ""
    echo "Porta 2022:"
    netstat -tlnp | grep ":2022" || echo "   ❌ Porta 2022 NÃO está escutando"
    echo ""
    echo "Porta 2025:"
    netstat -tlnp | grep ":2025" || echo "   ❌ Porta 2025 NÃO está escutando"
    echo ""
    
    echo "🔟 Verificando firewall externo..."
    echo ""
    echo "Testando acesso externo à porta 2022:"
    timeout 3 bash -c "</dev/tcp/82.25.92.217/2022" 2>/dev/null && echo "✅ Porta 2022 está acessível externamente" || echo "❌ Porta 2022 NÃO está acessível externamente"
    echo ""
    
    echo "=========================================="
    echo "✅ Testes concluídos!"
    echo "=========================================="
ENDSSH

