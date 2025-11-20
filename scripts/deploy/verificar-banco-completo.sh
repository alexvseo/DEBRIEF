#!/bin/bash

################################################################################
# Script para verificar status completo do banco de dados
# Testa conexão, configuração e funcionamento
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

echo "🔍 Verificação Completa do Banco de Dados"
echo "==========================================="
echo ""

# Executar verificações no servidor
ssh ${SERVER_USER}@${SERVER_HOST} << 'ENDSSH'
    set -e
    
    cd /root/debrief || { echo "❌ Diretório não encontrado"; exit 1; }
    
    echo "1️⃣  Verificando DATABASE_URL no docker-compose.yml..."
    echo ""
    grep DATABASE_URL docker-compose.yml
    echo ""
    
    echo "2️⃣  Verificando DATABASE_URL no container backend..."
    echo ""
    docker exec debrief-backend env | grep DATABASE_URL || echo "⚠️  Variável não encontrada"
    echo ""
    
    echo "3️⃣  Verificando se PostgreSQL está rodando..."
    echo ""
    if systemctl is-active --quiet postgresql; then
        echo "✅ PostgreSQL está rodando"
        systemctl status postgresql --no-pager | head -5
    else
        echo "❌ PostgreSQL NÃO está rodando"
        echo "   Tentando iniciar..."
        systemctl start postgresql
        sleep 2
    fi
    echo ""
    
    echo "4️⃣  Verificando se PostgreSQL está escutando na porta 5432..."
    echo ""
    if netstat -tlnp | grep -q ":5432"; then
        echo "✅ PostgreSQL está escutando na porta 5432"
        netstat -tlnp | grep ":5432"
    else
        echo "❌ PostgreSQL NÃO está escutando na porta 5432"
    fi
    echo ""
    
    echo "5️⃣  Testando conexão local com PostgreSQL..."
    echo ""
    export PGPASSWORD="Mslestrategia.2025@"
    if psql -h localhost -U postgres -d dbrief -c "SELECT version();" &> /dev/null; then
        echo "✅ Conexão local funciona"
        psql -h localhost -U postgres -d dbrief -c "SELECT version();" | head -3
    else
        echo "❌ Conexão local FALHOU"
        psql -h localhost -U postgres -d dbrief -c "SELECT 1;" 2>&1 | head -5
    fi
    echo ""
    
    echo "6️⃣  Verificando se banco 'dbrief' existe..."
    echo ""
    DB_EXISTS=$(psql -h localhost -U postgres -lqt | cut -d \| -f 1 | grep -w dbrief | wc -l)
    if [ "$DB_EXISTS" -eq 1 ]; then
        echo "✅ Banco 'dbrief' existe"
    else
        echo "❌ Banco 'dbrief' NÃO existe"
    fi
    echo ""
    
    echo "7️⃣  Verificando tabelas no banco..."
    echo ""
    psql -h localhost -U postgres -d dbrief -c "\dt" 2>&1 | head -20 || echo "⚠️  Erro ao listar tabelas"
    echo ""
    
    echo "8️⃣  Verificando usuários no banco..."
    echo ""
    psql -h localhost -U postgres -d dbrief -c "SELECT id, username, email, tipo, ativo FROM usuarios LIMIT 5;" 2>&1 || echo "⚠️  Tabela usuarios não existe ou erro"
    echo ""
    
    echo "9️⃣  Testando conexão do container backend com banco..."
    echo ""
    docker exec debrief-backend python -c "
import os
import sys
from sqlalchemy import create_engine, text

db_url = os.getenv('DATABASE_URL')
print(f'DATABASE_URL: {db_url[:70]}...')
print()

try:
    engine = create_engine(db_url, pool_pre_ping=True)
    print('✅ Engine criado com sucesso')
    
    with engine.connect() as conn:
        print('✅ Conectado ao banco de dados')
        result = conn.execute(text('SELECT current_database(), version()'))
        row = result.fetchone()
        print(f'   Banco atual: {row[0]}')
        print(f'   PostgreSQL: {row[1][:50]}...')
        
        # Verificar tabelas
        result = conn.execute(text(\"SELECT table_name FROM information_schema.tables WHERE table_schema = 'public'\"))
        tables = [row[0] for row in result.fetchall()]
        print(f'   Tabelas encontradas: {len(tables)}')
        if tables:
            print(f'   Primeiras tabelas: {', '.join(tables[:5])}')
        
        # Verificar usuários
        try:
            result = conn.execute(text('SELECT COUNT(*) FROM usuarios'))
            count = result.fetchone()[0]
            print(f'   Usuários no banco: {count}')
        except Exception as e:
            print(f'   ⚠️  Tabela usuarios não existe: {str(e)[:50]}')
        
    print()
    print('✅ ✅ CONEXÃO COM BANCO FUNCIONANDO PERFEITAMENTE!')
    
except Exception as e:
    print(f'❌ ERRO ao conectar: {type(e).__name__}')
    print(f'   Mensagem: {str(e)[:200]}')
    sys.exit(1)
" 2>&1
    echo ""
    
    echo "🔟 Verificando logs do backend (últimas 30 linhas)..."
    echo ""
    docker-compose logs --tail=30 backend | grep -E "banco|database|Connection|ERROR|WARNING|✅|iniciando|PostgreSQL" || docker-compose logs --tail=20 backend
    echo ""
    
    echo "1️⃣1️⃣  Testando endpoint de login..."
    echo ""
    LOGIN_RESPONSE=$(curl -s -X POST http://localhost:2025/api/auth/login \
        -H "Content-Type: application/x-www-form-urlencoded" \
        -d "username=admin&password=admin123" 2>&1)
    
    if echo "$LOGIN_RESPONSE" | grep -q "access_token"; then
        echo "✅ Login funciona!"
        echo "$LOGIN_RESPONSE" | python3 -m json.tool 2>/dev/null | head -10 || echo "$LOGIN_RESPONSE" | head -5
    else
        echo "❌ Login FALHOU"
        echo "Resposta:"
        echo "$LOGIN_RESPONSE"
    fi
    echo ""
    
    echo "=========================================="
    echo "✅ Verificação concluída!"
    echo "=========================================="
ENDSSH

