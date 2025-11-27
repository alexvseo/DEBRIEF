#!/bin/bash

# Script para Diagnosticar Erro 521 (Web server is down)
# Cloudflare Error 521 = Origin server não está respondendo

echo "=========================================="
echo "🔍 DIAGNÓSTICO ERRO 521 (WEB SERVER DOWN)"
echo "=========================================="
echo ""

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

SERVER="root@82.25.92.217"
APP_DIR="/var/www/debrief"

print_info "Conectando ao servidor $SERVER..."
echo ""

ssh $SERVER << 'ENDSSH'
    set -e
    
    cd /var/www/debrief || cd /root/debrief || { echo "❌ Diretório não encontrado"; exit 1; }
    
    echo "=========================================="
    echo "1️⃣  STATUS DOS CONTAINERS DOCKER"
    echo "=========================================="
    docker ps -a --filter "name=debrief" --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}"
    echo ""
    
    echo "=========================================="
    echo "2️⃣  STATUS DOCKER COMPOSE"
    echo "=========================================="
    docker-compose ps 2>/dev/null || docker compose ps 2>/dev/null || echo "⚠️  docker-compose não encontrado"
    echo ""
    
    echo "=========================================="
    echo "3️⃣  VERIFICANDO PORTAS ABERTAS"
    echo "=========================================="
    echo "Porta 2022 (Frontend):"
    netstat -tlnp 2>/dev/null | grep ":2022" || ss -tlnp 2>/dev/null | grep ":2022" || echo "❌ Porta 2022 NÃO está aberta"
    echo ""
    echo "Porta 2023 (Backend):"
    netstat -tlnp 2>/dev/null | grep ":2023" || ss -tlnp 2>/dev/null | grep ":2023" || echo "❌ Porta 2023 NÃO está aberta"
    echo ""
    echo "Porta 80 (HTTP padrão):"
    netstat -tlnp 2>/dev/null | grep ":80 " || ss -tlnp 2>/dev/null | grep ":80 " || echo "⚠️  Porta 80 não está aberta"
    echo ""
    echo "Porta 443 (HTTPS):"
    netstat -tlnp 2>/dev/null | grep ":443" || ss -tlnp 2>/dev/null | grep ":443" || echo "⚠️  Porta 443 não está aberta"
    echo ""
    
    echo "=========================================="
    echo "4️⃣  VERIFICANDO HEALTH DOS CONTAINERS"
    echo "=========================================="
    
    # Backend
    if docker ps --filter "name=debrief-backend" --format "{{.Names}}" | grep -q debrief-backend; then
        BACKEND_HEALTH=$(docker inspect debrief-backend --format='{{.State.Health.Status}}' 2>/dev/null || echo "no_healthcheck")
        BACKEND_STATUS=$(docker inspect debrief-backend --format='{{.State.Status}}' 2>/dev/null)
        echo "Backend Status: $BACKEND_STATUS"
        echo "Backend Health: $BACKEND_HEALTH"
        
        if [ "$BACKEND_STATUS" = "running" ]; then
            echo "✅ Backend está rodando"
        else
            echo "❌ Backend NÃO está rodando"
        fi
    else
        echo "❌ Container backend não encontrado"
    fi
    echo ""
    
    # Frontend
    if docker ps --filter "name=debrief-frontend" --format "{{.Names}}" | grep -q debrief-frontend; then
        FRONTEND_HEALTH=$(docker inspect debrief-frontend --format='{{.State.Health.Status}}' 2>/dev/null || echo "no_healthcheck")
        FRONTEND_STATUS=$(docker inspect debrief-frontend --format='{{.State.Status}}' 2>/dev/null)
        echo "Frontend Status: $FRONTEND_STATUS"
        echo "Frontend Health: $FRONTEND_HEALTH"
        
        if [ "$FRONTEND_STATUS" = "running" ]; then
            echo "✅ Frontend está rodando"
        else
            echo "❌ Frontend NÃO está rodando"
        fi
    else
        echo "❌ Container frontend não encontrado"
    fi
    echo ""
    
    echo "=========================================="
    echo "5️⃣  TESTANDO CONECTIVIDADE LOCAL"
    echo "=========================================="
    
    echo "Testando Frontend (localhost:2022):"
    curl -s -o /dev/null -w "HTTP Status: %{http_code}\n" --max-time 5 http://localhost:2022 || echo "❌ Falha ao conectar (timeout ou erro)"
    echo ""
    
    echo "Testando Backend (localhost:2023/health):"
    curl -s --max-time 5 http://localhost:2023/health || echo "❌ Falha ao conectar (timeout ou erro)"
    echo ""
    
    echo "Testando Backend API (localhost:2023/api/health):"
    curl -s --max-time 5 http://localhost:2023/api/health || echo "❌ Falha ao conectar (timeout ou erro)"
    echo ""
    
    echo "=========================================="
    echo "6️⃣  LOGS DO BACKEND (últimas 30 linhas)"
    echo "=========================================="
    docker logs debrief-backend --tail 30 2>&1 || echo "⚠️  Não foi possível obter logs do backend"
    echo ""
    
    echo "=========================================="
    echo "7️⃣  LOGS DO FRONTEND (últimas 20 linhas)"
    echo "=========================================="
    docker logs debrief-frontend --tail 20 2>&1 || echo "⚠️  Não foi possível obter logs do frontend"
    echo ""
    
    echo "=========================================="
    echo "8️⃣  VERIFICANDO FIREWALL"
    echo "=========================================="
    if command -v ufw &> /dev/null; then
        ufw status | head -20
    else
        echo "⚠️  UFW não instalado"
    fi
    echo ""
    
    echo "=========================================="
    echo "9️⃣  VERIFICANDO PROCESSOS DOCKER"
    echo "=========================================="
    ps aux | grep -E "docker|dockerd" | grep -v grep | head -5
    echo ""
    
    echo "=========================================="
    echo "🔟 VERIFICANDO ESPAÇO EM DISCO"
    echo "=========================================="
    df -h | grep -E "Filesystem|/dev/|/var/lib/docker"
    echo ""
    
    echo "=========================================="
    echo "1️⃣1️⃣  VERIFICANDO MEMÓRIA"
    echo "=========================================="
    free -h
    echo ""
    
    echo "=========================================="
    echo "1️⃣2️⃣  VERIFICANDO REDE DOCKER"
    echo "=========================================="
    docker network ls | grep debrief || echo "⚠️  Rede debrief não encontrada"
    echo ""
    
ENDSSH

if [ $? -eq 0 ]; then
    echo ""
    print_success "Diagnóstico concluído!"
    echo ""
    echo "📋 PRÓXIMOS PASSOS:"
    echo "1. Se containers estão parados: docker-compose up -d"
    echo "2. Se containers estão unhealthy: verificar logs e reiniciar"
    echo "3. Se portas não estão abertas: verificar firewall e configuração"
    echo "4. Se Cloudflare ainda mostra 521: verificar configuração do proxy no Cloudflare"
    echo ""
else
    print_error "Falha ao conectar ao servidor ou executar diagnóstico"
    exit 1
fi


