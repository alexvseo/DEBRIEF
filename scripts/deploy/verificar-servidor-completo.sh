#!/bin/bash

################################################################################
# Script para verificar status completo do servidor
# Verifica containers, portas, firewall, e conectividade
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

echo "🔍 Verificação Completa do Servidor DeBrief"
echo "============================================"
echo ""

# Executar verificações no servidor
ssh ${SERVER_USER}@${SERVER_HOST} << 'ENDSSH'
    set -e
    
    cd /root/debrief || { echo "❌ Diretório não encontrado"; exit 1; }
    
    echo "1️⃣  Verificando status dos containers..."
    echo ""
    docker-compose ps
    echo ""
    
    echo "2️⃣  Verificando se portas estão abertas..."
    echo ""
    echo "Porta 2022 (Frontend/Caddy):"
    netstat -tlnp | grep ":2022" || echo "❌ Porta 2022 NÃO está aberta"
    echo ""
    echo "Porta 2025 (Backend):"
    netstat -tlnp | grep ":2025" || echo "❌ Porta 2025 NÃO está aberta"
    echo ""
    echo "Porta 8000 (Backend interno):"
    netstat -tlnp | grep ":8000" || echo "⚠️  Porta 8000 não exposta (normal)"
    echo ""
    
    echo "3️⃣  Verificando firewall (UFW)..."
    echo ""
    if command -v ufw &> /dev/null; then
        ufw status | grep -E "2022|2025|Status" || echo "UFW não configurado ou desabilitado"
    else
        echo "⚠️  UFW não instalado"
    fi
    echo ""
    
    echo "4️⃣  Verificando logs do Caddy (últimas 20 linhas)..."
    echo ""
    docker-compose logs --tail=20 caddy
    echo ""
    
    echo "5️⃣  Verificando logs do Backend (últimas 15 linhas)..."
    echo ""
    docker-compose logs --tail=15 backend | grep -E "ERROR|WARNING|iniciando|banco|Connection" || docker-compose logs --tail=15 backend
    echo ""
    
    echo "6️⃣  Verificando logs do Frontend (últimas 10 linhas)..."
    echo ""
    docker-compose logs --tail=10 frontend
    echo ""
    
    echo "7️⃣  Testando conectividade local..."
    echo ""
    echo "Testando Caddy (localhost:2022):"
    curl -s -o /dev/null -w "HTTP Status: %{http_code}\n" http://localhost:2022 || echo "❌ Falha ao conectar"
    echo ""
    echo "Testando Backend (localhost:2025/health):"
    curl -s http://localhost:2025/health || echo "❌ Falha ao conectar"
    echo ""
    
    echo "8️⃣  Verificando rede Docker..."
    echo ""
    docker network inspect debrief-network 2>/dev/null | grep -E "Name|Driver|Containers" || echo "⚠️  Rede não encontrada"
    echo ""
    
    echo "9️⃣  Verificando processos Docker..."
    echo ""
    docker ps --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}" | grep debrief
    echo ""
    
    echo "🔟 Verificando se Caddyfile existe e está correto..."
    echo ""
    if [ -f "Caddyfile" ]; then
        echo "✅ Caddyfile existe"
        echo "Conteúdo:"
        cat Caddyfile
    else
        echo "❌ Caddyfile NÃO existe!"
    fi
    echo ""
    
    echo "=========================================="
    echo "✅ Verificação concluída!"
    echo "=========================================="
ENDSSH

