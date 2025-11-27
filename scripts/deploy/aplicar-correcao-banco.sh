#!/bin/bash

################################################################################
# Script para aplicar correção do banco de dados no servidor
# Executa: git pull, atualiza DATABASE_URL, recria container
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

echo "🔧 Aplicando Correção do Banco de Dados no Servidor"
echo "===================================================="
echo ""

# Executar no servidor
ssh ${SERVER_USER}@${SERVER_HOST} << 'ENDSSH'
    set -e
    
    cd /root/debrief || { echo "❌ Diretório não encontrado"; exit 1; }
    
    echo "1️⃣  Atualizando código do Git..."
    git pull || { echo "⚠️  Git pull falhou, continuando..."; }
    
    echo ""
    echo "2️⃣  Verificando DATABASE_URL atual..."
    if grep -q "localhost:5432" docker-compose.yml; then
        echo "⚠️  Ainda está usando localhost:5432"
        echo "3️⃣  Aplicando correção..."
        sed -i 's|postgresql://postgres:<redacted-legacy-password-encoded>@localhost:5432/dbrief|postgresql://postgres:<redacted-legacy-password-encoded>@host.docker.internal:5432/dbrief|g' docker-compose.yml
        echo "✅ Correção aplicada"
    else
        echo "✅ DATABASE_URL já está correto"
    fi
    
    echo ""
    echo "4️⃣  Verificando configuração..."
    grep DATABASE_URL docker-compose.yml | head -1
    
    echo ""
    echo "5️⃣  Parando backend..."
    docker-compose stop backend || true
    
    echo ""
    echo "6️⃣  Removendo container backend..."
    docker-compose rm -f backend || true
    
    echo ""
    echo "7️⃣  Recriando backend..."
    docker-compose up -d backend
    
    echo ""
    echo "8️⃣  Aguardando inicialização (15 segundos)..."
    sleep 15
    
    echo ""
    echo "9️⃣  Verificando logs..."
    docker-compose logs --tail=30 backend | grep -E "banco|database|Connection|ERROR|WARNING|✅|iniciando" || docker-compose logs --tail=20 backend
    
    echo ""
    echo "🔟 Testando conexão..."
    docker exec debrief-backend python -c "
import os
from sqlalchemy import create_engine, text

db_url = os.getenv('DATABASE_URL')
print(f'DATABASE_URL: {db_url[:50]}...')

try:
    engine = create_engine(db_url)
    with engine.connect() as conn:
        result = conn.execute(text('SELECT 1 as test'))
        print('✅ ✅ Conexão com banco de dados FUNCIONOU!')
        print(f'Resultado: {result.fetchone()}')
except Exception as e:
    print(f'❌ Erro ao conectar: {str(e)[:100]}')
" 2>&1 || echo "⚠️  Teste de conexão falhou, verifique os logs acima"
    
    echo ""
    echo "=========================================="
    echo "✅ Correção aplicada!"
    echo "=========================================="
    echo ""
    echo "Verifique os logs acima para confirmar se está funcionando."
ENDSSH

if [ $? -eq 0 ]; then
    print_success "✅ Script executado com sucesso!"
else
    print_error "❌ Erro ao executar script"
    exit 1
fi

