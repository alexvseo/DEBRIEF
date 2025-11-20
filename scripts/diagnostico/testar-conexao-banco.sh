#!/bin/bash

# Script para Testar Conexão com Banco de Dados PostgreSQL
# Execute no servidor: ./testar-conexao-banco.sh

echo "=========================================="
echo "🔍 TESTE DE CONEXÃO COM BANCO DE DADOS"
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

# Configurações do banco
DB_HOST="82.25.92.217"
DB_PORT="5432"
DB_NAME="dbrief"
DB_USER="root"
DB_PASS="Mslestrategia.2025@"

echo "Configurações:"
echo "  Host: $DB_HOST"
echo "  Porta: $DB_PORT"
echo "  Banco: $DB_NAME"
echo "  Usuário: $DB_USER"
echo ""

# 1. Testar se porta está aberta
print_info "1️⃣  Testando se porta $DB_PORT está acessível..."
if timeout 5 bash -c "echo > /dev/tcp/$DB_HOST/$DB_PORT" 2>/dev/null; then
    print_success "Porta $DB_PORT está acessível"
else
    print_error "Porta $DB_PORT não está acessível (timeout)"
    echo ""
    print_warning "Possíveis causas:"
    echo "  - Firewall bloqueando a porta"
    echo "  - PostgreSQL não está rodando"
    echo "  - PostgreSQL não está configurado para aceitar conexões remotas"
    echo ""
    print_info "Verificando firewall..."
    if command -v ufw &> /dev/null; then
        ufw status | grep -E "5432|PostgreSQL" || print_warning "Porta 5432 não encontrada nas regras do ufw"
    fi
    exit 1
fi
echo ""

# 2. Testar conexão com psql (se disponível)
print_info "2️⃣  Testando conexão com psql..."
if command -v psql &> /dev/null; then
    export PGPASSWORD="$DB_PASS"
    if psql -h "$DB_HOST" -p "$DB_PORT" -U "$DB_USER" -d "$DB_NAME" -c "SELECT version();" 2>&1 | grep -q "PostgreSQL"; then
        print_success "Conexão com psql funcionando!"
        psql -h "$DB_HOST" -p "$DB_PORT" -U "$DB_USER" -d "$DB_NAME" -c "SELECT version();" 2>&1 | head -3
    else
        print_error "Conexão com psql falhou"
        psql -h "$DB_HOST" -p "$DB_PORT" -U "$DB_USER" -d "$DB_NAME" -c "SELECT version();" 2>&1 | head -5
    fi
    unset PGPASSWORD
else
    print_warning "psql não está instalado (pulando teste)"
fi
echo ""

# 3. Testar conexão com Python (simulando backend)
print_info "3️⃣  Testando conexão com Python (simulando backend)..."
python3 << EOF
import sys
try:
    import psycopg2
    print("✅ psycopg2 instalado")
    
    try:
        conn = psycopg2.connect(
            host="$DB_HOST",
            port=$DB_PORT,
            database="$DB_NAME",
            user="$DB_USER",
            password="$DB_PASS",
            connect_timeout=5
        )
        print("✅ Conexão estabelecida com sucesso!")
        
        cur = conn.cursor()
        cur.execute("SELECT version();")
        version = cur.fetchone()
        print(f"✅ PostgreSQL versão: {version[0][:50]}...")
        
        cur.execute("SELECT current_database();")
        db = cur.fetchone()
        print(f"✅ Banco de dados atual: {db[0]}")
        
        cur.close()
        conn.close()
        sys.exit(0)
    except psycopg2.OperationalError as e:
        print(f"❌ Erro de conexão: {e}")
        sys.exit(1)
    except Exception as e:
        print(f"❌ Erro inesperado: {e}")
        sys.exit(1)
except ImportError:
    print("⚠️  psycopg2 não está instalado")
    print("   Instale com: pip install psycopg2-binary")
    sys.exit(1)
EOF

PYTHON_EXIT=$?
echo ""

if [ $PYTHON_EXIT -eq 0 ]; then
    print_success "✅ Todos os testes passaram!"
    echo ""
    print_info "O banco de dados está acessível e funcionando."
    print_info "O problema pode estar no container Docker ou na rede."
else
    print_error "❌ Teste de conexão falhou"
    echo ""
    print_warning "Próximos passos:"
    echo "  1. Verificar se PostgreSQL está rodando no servidor"
    echo "  2. Verificar configuração do PostgreSQL (postgresql.conf e pg_hba.conf)"
    echo "  3. Verificar firewall (ufw ou iptables)"
    echo "  4. Executar: ./configurar-postgresql-remoto.sh"
fi
echo ""

