#!/bin/bash

################################################################################
# Script para testar conexão com banco de dados remoto
# Verifica se é possível conectar ao PostgreSQL do servidor
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

echo "🔍 Testando conexão com banco de dados remoto..."
echo ""

# Configurações
DB_HOST="82.25.92.217"
DB_PORT="5432"
DB_USER="postgres"
DB_PASSWORD="<redacted-db-password>"
DB_NAME="dbrief"

# 1. Verificar se psql está instalado
print_info "1️⃣  Verificando se psql está instalado..."
if command -v psql &> /dev/null; then
    PSQL_VERSION=$(psql --version | head -n1)
    print_success "psql encontrado: $PSQL_VERSION"
else
    print_warning "psql não encontrado. Tentando com Python..."
    USE_PYTHON=true
fi
echo ""

# 2. Testar conectividade de rede
print_info "2️⃣  Testando conectividade de rede ($DB_HOST:$DB_PORT)..."
if command -v nc &> /dev/null || command -v telnet &> /dev/null; then
    if nc -z -w5 "$DB_HOST" "$DB_PORT" 2>/dev/null || timeout 5 bash -c "echo > /dev/tcp/$DB_HOST/$DB_PORT" 2>/dev/null; then
        print_success "Porta $DB_PORT está acessível em $DB_HOST"
    else
        print_error "Porta $DB_PORT NÃO está acessível em $DB_HOST"
        print_warning "Verifique:"
        echo "  - Firewall local permite conexão com $DB_HOST:$DB_PORT"
        echo "  - Servidor PostgreSQL está rodando e aceita conexões remotas"
        echo "  - Sua conexão de internet está funcionando"
        exit 1
    fi
else
    print_warning "Ferramentas de teste de rede não encontradas. Pulando teste de conectividade."
fi
echo ""

# 3. Testar conexão com psql
if [ -z "$USE_PYTHON" ]; then
    print_info "3️⃣  Testando conexão com psql..."
    export PGPASSWORD="$DB_PASSWORD"
    
    if psql -h "$DB_HOST" -p "$DB_PORT" -U "$DB_USER" -d "$DB_NAME" -c "SELECT version();" -t 2>/dev/null | head -n1 > /dev/null; then
        DB_VERSION=$(psql -h "$DB_HOST" -p "$DB_PORT" -U "$DB_USER" -d "$DB_NAME" -c "SELECT version();" -t 2>/dev/null | head -n1 | xargs)
        print_success "Conexão com PostgreSQL funcionou!"
        print_info "Versão: ${DB_VERSION:0:50}..."
        
        # Testar algumas queries
        TABLE_COUNT=$(psql -h "$DB_HOST" -p "$DB_PORT" -U "$DB_USER" -d "$DB_NAME" -c "SELECT COUNT(*) FROM information_schema.tables WHERE table_schema = 'public';" -t 2>/dev/null | xargs)
        print_info "Tabelas no banco: $TABLE_COUNT"
    else
        print_error "Falha ao conectar com psql"
        USE_PYTHON=true
    fi
    unset PGPASSWORD
    echo ""
fi

# 4. Testar conexão com Python (fallback)
if [ "$USE_PYTHON" = true ]; then
    print_info "3️⃣  Testando conexão com Python..."
    
    python3 << PYTHON_SCRIPT
import sys
import psycopg2
from urllib.parse import quote_plus

try:
    # Construir connection string
    conn = psycopg2.connect(
        host="$DB_HOST",
        port=$DB_PORT,
        user="$DB_USER",
        password="$DB_PASSWORD",
        database="$DB_NAME",
        connect_timeout=10
    )
    
    cursor = conn.cursor()
    
    # Testar versão
    cursor.execute("SELECT version();")
    version = cursor.fetchone()[0]
    print("✅ Conexão com PostgreSQL funcionou!")
    print(f"Versão: {version[:50]}...")
    
    # Contar tabelas
    cursor.execute("""
        SELECT COUNT(*) 
        FROM information_schema.tables 
        WHERE table_schema = 'public';
    """)
    table_count = cursor.fetchone()[0]
    print(f"Tabelas no banco: {table_count}")
    
    # Testar algumas tabelas principais
    cursor.execute("""
        SELECT table_name 
        FROM information_schema.tables 
        WHERE table_schema = 'public' 
        AND table_name IN ('users', 'clientes', 'demandas', 'secretarias')
        ORDER BY table_name;
    """)
    tables = cursor.fetchall()
    if tables:
        print("Tabelas principais encontradas:")
        for table in tables:
            print(f"  - {table[0]}")
    
    cursor.close()
    conn.close()
    sys.exit(0)
    
except psycopg2.OperationalError as e:
    print(f"❌ Erro de conexão: {e}")
    sys.exit(1)
except Exception as e:
    print(f"❌ Erro: {e}")
    sys.exit(1)
PYTHON_SCRIPT

    if [ $? -eq 0 ]; then
        print_success "Teste com Python concluído com sucesso!"
    else
        print_error "Falha no teste com Python"
        exit 1
    fi
    echo ""
fi

# 5. Resumo final
print_success "🎉 Todos os testes de conexão passaram!"
echo ""
print_info "Próximos passos:"
echo "  1. Execute: ./scripts/dev/iniciar-dev-local.sh"
echo "  2. Acesse o frontend em: http://localhost:5173"
echo "  3. Acesse o backend em: http://localhost:8000/api/docs"
echo ""

