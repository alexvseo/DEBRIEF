#!/bin/bash

################################################################################
# Script para diagnosticar problemas no servidor
# Verifica logs, conectividade e configurações
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

echo "🔍 Diagnóstico Completo do Servidor"
echo "===================================="
echo ""

# Executar diagnóstico no servidor
ssh ${SERVER_USER}@${SERVER_HOST} << 'ENDSSH'
    set -e
    
    cd /root/debrief || { echo "❌ Diretório não encontrado"; exit 1; }
    
    echo "1️⃣  Status dos Containers:"
    echo ""
    docker-compose ps
    echo ""
    
    echo "2️⃣  Testando Backend localmente..."
    echo ""
    BACKEND_TEST=$(curl -s -o /dev/null -w "%{http_code}" http://localhost:2025/health 2>&1 || echo "FAILED")
    if [ "$BACKEND_TEST" = "200" ]; then
        echo "✅ Backend responde (HTTP $BACKEND_TEST)"
        curl -s http://localhost:2025/health | head -1
    else
        echo "❌ Backend NÃO responde (Status: $BACKEND_TEST)"
    fi
    echo ""
    
    echo "3️⃣  Testando Frontend localmente..."
    echo ""
    FRONTEND_TEST=$(curl -s -o /dev/null -w "%{http_code}" http://localhost:80 2>&1 || echo "FAILED")
    if [ "$FRONTEND_TEST" = "200" ] || [ "$FRONTEND_TEST" = "301" ] || [ "$FRONTEND_TEST" = "302" ]; then
        echo "✅ Frontend responde (HTTP $FRONTEND_TEST)"
    else
        echo "❌ Frontend NÃO responde (Status: $FRONTEND_TEST)"
        echo "   Tentando acessar via container..."
        docker exec debrief-frontend wget -q -O- http://localhost:80 | head -5 || echo "   Container não responde"
    fi
    echo ""
    
    echo "4️⃣  Testando Caddy localmente..."
    echo ""
    CADDY_TEST=$(curl -s -o /dev/null -w "%{http_code}" http://localhost:2022 2>&1 || echo "FAILED")
    if [ "$CADDY_TEST" = "200" ] || [ "$CADDY_TEST" = "301" ] || [ "$CADDY_TEST" = "302" ]; then
        echo "✅ Caddy responde (HTTP $CADDY_TEST)"
        curl -s http://localhost:2022 | head -10
    else
        echo "❌ Caddy NÃO responde (Status: $CADDY_TEST)"
    fi
    echo ""
    
    echo "5️⃣  Testando API via Caddy..."
    echo ""
    API_TEST=$(curl -s -o /dev/null -w "%{http_code}" http://localhost:2022/api/health 2>&1 || echo "FAILED")
    if [ "$API_TEST" = "200" ]; then
        echo "✅ API via Caddy responde (HTTP $API_TEST)"
        curl -s http://localhost:2022/api/health | head -1
    else
        echo "❌ API via Caddy NÃO responde (Status: $API_TEST)"
    fi
    echo ""
    
    echo "6️⃣  Logs do Caddy (últimas 30 linhas)..."
    echo ""
    docker-compose logs --tail=30 caddy
    echo ""
    
    echo "7️⃣  Logs do Frontend (últimas 20 linhas)..."
    echo ""
    docker-compose logs --tail=20 frontend
    echo ""
    
    echo "8️⃣  Verificando Caddyfile..."
    echo ""
    if [ -f "Caddyfile" ]; then
        echo "✅ Caddyfile existe:"
        cat Caddyfile
    else
        echo "❌ Caddyfile NÃO existe!"
    fi
    echo ""
    
    echo "9️⃣  Verificando rede Docker..."
    echo ""
    docker network inspect debrief-network 2>/dev/null | grep -A 5 "Containers" || echo "⚠️  Rede não encontrada"
    echo ""
    
    echo "🔟 Verificando se Caddy consegue acessar frontend..."
    echo ""
    docker exec debrief-caddy wget -q -O- http://debrief-frontend:80 2>&1 | head -5 || echo "❌ Caddy não consegue acessar frontend"
    echo ""
    
    echo "1️⃣1️⃣  Verificando se Caddy consegue acessar backend..."
    echo ""
    docker exec debrief-caddy wget -q -O- http://debrief-backend:8000/health 2>&1 | head -5 || echo "❌ Caddy não consegue acessar backend"
    echo ""
    
    echo "=========================================="
    echo "✅ Diagnóstico concluído!"
    echo "=========================================="
ENDSSH

