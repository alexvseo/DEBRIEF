#!/bin/bash

################################################################################
# Script para testar conexão do container com banco
# Diagnóstico completo de conectividade
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

echo "🔍 Testando Conexão do Container com Banco"
echo "==========================================="
echo ""

# Executar no servidor
ssh ${SERVER_USER}@${SERVER_HOST} << 'ENDSSH'
    set -e
    
    cd /root/debrief || { echo "❌ Diretório não encontrado"; exit 1; }
    
    echo "1️⃣  Verificando se host.docker.internal está acessível..."
    echo ""
    if docker exec debrief-backend ping -c 2 host.docker.internal &> /dev/null; then
        echo "✅ host.docker.internal está acessível"
    else
        echo "❌ host.docker.internal NÃO está acessível"
        echo "   Verificando IP do docker0..."
        DOCKER_IP=$(ip addr show docker0 | grep 'inet ' | awk '{print $2}' | cut -d/ -f1)
        if [ -n "$DOCKER_IP" ]; then
            echo "   IP do docker0: $DOCKER_IP"
        else
            echo "   ⚠️  docker0 não encontrado"
        fi
    fi
    echo ""
    
    echo "2️⃣  Verificando se container consegue acessar porta 5432..."
    echo ""
    if docker exec debrief-backend timeout 3 bash -c "</dev/tcp/host.docker.internal/5432" 2>/dev/null; then
        echo "✅ Container consegue acessar porta 5432 via host.docker.internal"
    else
        echo "❌ Container NÃO consegue acessar porta 5432"
        echo "   Tentando com IP do docker0..."
        DOCKER_IP=$(ip addr show docker0 | grep 'inet ' | awk '{print $2}' | cut -d/ -f1)
        if [ -n "$DOCKER_IP" ]; then
            if docker exec debrief-backend timeout 3 bash -c "</dev/tcp/$DOCKER_IP/5432" 2>/dev/null; then
                echo "✅ Container consegue acessar via $DOCKER_IP:5432"
                echo "   ⚠️  Precisa atualizar DATABASE_URL para usar $DOCKER_IP"
            else
                echo "❌ Container NÃO consegue acessar via $DOCKER_IP:5432"
            fi
        fi
    fi
    echo ""
    
    echo "3️⃣  Verificando DATABASE_URL no container..."
    echo ""
    DB_URL=$(docker exec debrief-backend env | grep DATABASE_URL | cut -d= -f2-)
    echo "DATABASE_URL: ${DB_URL:0:80}..."
    echo ""
    
    echo "4️⃣  Testando conexão simples (timeout 5s)..."
    echo ""
    timeout 10 docker exec debrief-backend python3 -c "
import os
import sys
from sqlalchemy import create_engine, text

db_url = os.getenv('DATABASE_URL')
print(f'Testando: {db_url[:60]}...')

try:
    engine = create_engine(db_url, pool_pre_ping=True, connect_args={'connect_timeout': 5})
    print('✅ Engine criado')
    
    with engine.connect() as conn:
        print('✅ Conectado!')
        result = conn.execute(text('SELECT current_database()'))
        db_name = result.fetchone()[0]
        print(f'✅ Banco: {db_name}')
        
        result = conn.execute(text('SELECT COUNT(*) FROM users'))
        count = result.fetchone()[0]
        print(f'✅ Usuários: {count}')
        
    print('✅ ✅ CONEXÃO FUNCIONANDO!')
    sys.exit(0)
    
except Exception as e:
    print(f'❌ ERRO: {type(e).__name__}')
    print(f'   {str(e)[:200]}')
    sys.exit(1)
" 2>&1
    echo ""
    
    echo "5️⃣  Verificando logs do backend..."
    echo ""
    docker-compose logs --tail=20 backend | grep -E "Connection|ERROR|WARNING|banco|database" || echo "   Nenhum erro recente"
    echo ""
    
    echo "6️⃣  Verificando rede Docker..."
    echo ""
    docker network inspect debrief-network --format '{{range .Containers}}{{.Name}} {{end}}' 2>/dev/null || echo "⚠️  Rede não encontrada"
    echo ""
    
    echo "=========================================="
    echo "✅ Teste concluído!"
    echo "=========================================="
ENDSSH

