#!/bin/bash

################################################################################
# Script para corrigir banco de dados e login
# Aplica todas as correções necessárias
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

echo "🔧 Corrigindo Banco de Dados e Login"
echo "===================================="
echo ""

# Executar no servidor
ssh ${SERVER_USER}@${SERVER_HOST} << 'ENDSSH'
    set -e
    
    cd /root/debrief || { echo "❌ Diretório não encontrado"; exit 1; }
    
    echo "1️⃣  Atualizando código..."
    git pull || echo "⚠️  Git pull falhou, continuando..."
    echo ""
    
    echo "2️⃣  Verificando DATABASE_URL atual..."
    if grep -q "localhost:5432" docker-compose.yml; then
        echo "⚠️  Ainda está usando localhost:5432"
        echo "3️⃣  Aplicando correção..."
        sed -i 's|postgresql://postgres:Mslestrategia.2025%40@localhost:5432/dbrief|postgresql://postgres:Mslestrategia.2025%40@host.docker.internal:5432/dbrief|g' docker-compose.yml
        echo "✅ Correção aplicada"
    else
        echo "✅ DATABASE_URL já está correto"
    fi
    echo ""
    
    echo "4️⃣  Verificando configuração final..."
    grep DATABASE_URL docker-compose.yml | head -1
    echo ""
    
    echo "5️⃣  Verificando se PostgreSQL está rodando..."
    if systemctl is-active --quiet postgresql; then
        echo "✅ PostgreSQL está rodando"
    else
        echo "❌ PostgreSQL NÃO está rodando"
        echo "   Iniciando PostgreSQL..."
        systemctl start postgresql
        sleep 2
    fi
    echo ""
    
    echo "6️⃣  Testando conexão local com PostgreSQL..."
    export PGPASSWORD="Mslestra@2025"
    if psql -h localhost -U postgres -d dbrief -c "SELECT 1;" &> /dev/null; then
        echo "✅ Conexão local funciona"
    else
        echo "❌ Conexão local FALHOU"
    fi
    echo ""
    
    echo "7️⃣  Parando backend..."
    docker-compose stop backend || true
    docker-compose rm -f backend || true
    echo ""
    
    echo "8️⃣  Recriando backend..."
    docker-compose up -d backend
    echo ""
    
    echo "9️⃣  Aguardando inicialização (20 segundos)..."
    sleep 20
    echo ""
    
    echo "🔟 Verificando logs do backend..."
    docker-compose logs --tail=30 backend | grep -E "banco|database|Connection|ERROR|WARNING|✅|iniciando" || docker-compose logs --tail=20 backend
    echo ""
    
    echo "1️⃣1️⃣  Testando conexão do container com banco..."
    docker exec debrief-backend python -c "
import os
from sqlalchemy import create_engine, text

db_url = os.getenv('DATABASE_URL')
print(f'DATABASE_URL: {db_url[:60]}...')

try:
    engine = create_engine(db_url)
    with engine.connect() as conn:
        result = conn.execute(text('SELECT 1 as test'))
        print('✅ ✅ Conexão com banco FUNCIONOU!')
        print(f'Resultado: {result.fetchone()}')
except Exception as e:
    print(f'❌ Erro: {str(e)[:150]}')
" 2>&1
    echo ""
    
    echo "1️⃣2️⃣  Testando endpoint de login..."
    LOGIN_TEST=$(curl -s -X POST http://localhost:2025/api/auth/login \
        -H "Content-Type: application/x-www-form-urlencoded" \
        -d "username=admin&password=admin123" 2>&1 | head -1)
    
    if echo "$LOGIN_TEST" | grep -q "access_token"; then
        echo "✅ Login funciona!"
        echo "$LOGIN_TEST" | head -1
    else
        echo "❌ Login FALHOU"
        echo "Resposta: $LOGIN_TEST"
    fi
    echo ""
    
    echo "=========================================="
    echo "✅ Correção aplicada!"
    echo "=========================================="
ENDSSH

