#!/bin/bash

################################################################################
# Script para corrigir conexão do banco de dados no servidor
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

echo "🔧 Corrigindo Conexão do Banco de Dados no Servidor"
echo "=================================================="
echo ""

# 1. Verificar se PostgreSQL está rodando
print_info "1️⃣  Verificando se PostgreSQL está rodando..."
ssh ${SERVER_USER}@${SERVER_HOST} << 'ENDSSH'
    if systemctl is-active --quiet postgresql; then
        echo "✅ PostgreSQL está rodando"
    else
        echo "❌ PostgreSQL NÃO está rodando"
        echo "Iniciando PostgreSQL..."
        systemctl start postgresql
        sleep 2
    fi
ENDSSH

# 2. Verificar se PostgreSQL está escutando na porta 5432
print_info "2️⃣  Verificando se PostgreSQL está escutando na porta 5432..."
ssh ${SERVER_USER}@${SERVER_HOST} << 'ENDSSH'
    if netstat -tlnp | grep -q ":5432"; then
        echo "✅ PostgreSQL está escutando na porta 5432"
        netstat -tlnp | grep ":5432"
    else
        echo "❌ PostgreSQL NÃO está escutando na porta 5432"
        exit 1
    fi
ENDSSH

# 3. Testar conexão local
print_info "3️⃣  Testando conexão local com PostgreSQL..."
ssh ${SERVER_USER}@${SERVER_HOST} << 'ENDSSH'
    export PGPASSWORD="Mslestrategia.2025@"
    if psql -h localhost -U postgres -d dbrief -c "SELECT 1;" &> /dev/null; then
        echo "✅ Conexão local funciona"
    else
        echo "❌ Conexão local FALHOU"
        echo "Verificando configuração do PostgreSQL..."
        echo "listen_addresses:"
        grep listen_addresses /etc/postgresql/*/main/postgresql.conf 2>/dev/null || echo "Arquivo não encontrado"
    fi
ENDSSH

# 4. Verificar IP do docker0
print_info "4️⃣  Verificando IP da interface docker0..."
DOCKER_IP=$(ssh ${SERVER_USER}@${SERVER_HOST} "ip addr show docker0 | grep 'inet ' | awk '{print \$2}' | cut -d/ -f1" 2>/dev/null || echo "")
if [ -n "$DOCKER_IP" ]; then
    print_success "IP do docker0: $DOCKER_IP"
else
    print_warning "docker0 não encontrado, tentando host.docker.internal"
    DOCKER_IP="host.docker.internal"
fi

# 5. Atualizar docker-compose.yml
print_info "5️⃣  Atualizando docker-compose.yml..."
ssh ${SERVER_USER}@${SERVER_HOST} << ENDSSH
    cd ${PROJECT_DIR}
    
    # Fazer backup
    cp docker-compose.yml docker-compose.yml.backup
    
    # Atualizar DATABASE_URL
    if grep -q "localhost:5432" docker-compose.yml; then
        sed -i 's|postgresql://postgres:Mslestrategia.2025%40@localhost:5432/dbrief|postgresql://postgres:Mslestrategia.2025%40@${DOCKER_IP}:5432/dbrief|g' docker-compose.yml
        echo "✅ docker-compose.yml atualizado"
    else
        echo "⚠️  DATABASE_URL já está configurado diferente"
    fi
ENDSSH

# 6. Reiniciar backend
print_info "6️⃣  Reiniciando backend..."
ssh ${SERVER_USER}@${SERVER_HOST} << 'ENDSSH'
    cd /root/debrief
    docker-compose restart backend
    sleep 10
ENDSSH

# 7. Verificar logs
print_info "7️⃣  Verificando logs do backend..."
ssh ${SERVER_USER}@${SERVER_HOST} << 'ENDSSH'
    cd /root/debrief
    echo "Últimas 15 linhas dos logs:"
    docker-compose logs --tail=15 backend | grep -E "banco|database|Connection|ERROR|WARNING|✅|iniciando" || docker-compose logs --tail=15 backend
ENDSSH

# 8. Testar conexão do container
print_info "8️⃣  Testando conexão do container com o banco..."
ssh ${SERVER_USER}@${SERVER_HOST} << ENDSSH
    cd /root/debrief
    docker exec debrief-backend python -c "
import os
from sqlalchemy import create_engine, text

db_url = os.getenv('DATABASE_URL')
print(f'DATABASE_URL: {db_url}')

try:
    engine = create_engine(db_url)
    with engine.connect() as conn:
        result = conn.execute(text('SELECT 1 as test'))
        print('✅ Conexão com banco de dados funcionou!')
        print(f'Resultado: {result.fetchone()}')
except Exception as e:
    print(f'❌ Erro ao conectar: {e}')
" 2>&1
ENDSSH

echo ""
print_success "✅ Correção aplicada!"
print_info "Verifique os logs acima para confirmar se a conexão está funcionando."

