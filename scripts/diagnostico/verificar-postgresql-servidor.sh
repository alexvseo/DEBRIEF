#!/bin/bash

################################################################################
# Script para verificar PostgreSQL no servidor
# Diagnostica problemas de conexão do backend com o banco
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

echo "🔍 Verificando PostgreSQL no servidor..."
echo ""

# 1. Verificar se PostgreSQL está instalado
print_info "1️⃣  Verificando se PostgreSQL está instalado..."
if command -v psql &> /dev/null; then
    PSQL_VERSION=$(psql --version | head -n1)
    print_success "PostgreSQL encontrado: $PSQL_VERSION"
else
    print_error "PostgreSQL não encontrado!"
    exit 1
fi
echo ""

# 2. Verificar se PostgreSQL está rodando
print_info "2️⃣  Verificando se PostgreSQL está rodando..."
if systemctl is-active --quiet postgresql || systemctl is-active --quiet postgresql@*-main; then
    print_success "PostgreSQL está rodando"
    systemctl status postgresql --no-pager -l | head -n 5
else
    print_error "PostgreSQL NÃO está rodando!"
    print_info "Tentando iniciar PostgreSQL..."
    sudo systemctl start postgresql || sudo systemctl start postgresql@*-main || true
    sleep 2
    if systemctl is-active --quiet postgresql || systemctl is-active --quiet postgresql@*-main; then
        print_success "PostgreSQL iniciado com sucesso"
    else
        print_error "Não foi possível iniciar PostgreSQL"
        exit 1
    fi
fi
echo ""

# 3. Verificar em qual porta está escutando
print_info "3️⃣  Verificando porta do PostgreSQL..."
if netstat -tlnp 2>/dev/null | grep -q ":5432" || ss -tlnp 2>/dev/null | grep -q ":5432"; then
    print_success "PostgreSQL está escutando na porta 5432"
    netstat -tlnp 2>/dev/null | grep ":5432" || ss -tlnp 2>/dev/null | grep ":5432"
else
    print_error "PostgreSQL NÃO está escutando na porta 5432"
    print_info "Verificando postgresql.conf..."
    if [ -f /etc/postgresql/*/main/postgresql.conf ]; then
        grep "port" /etc/postgresql/*/main/postgresql.conf | grep -v "^#" || print_warning "Porta não encontrada em postgresql.conf"
    fi
fi
echo ""

# 4. Verificar se está escutando em localhost
print_info "4️⃣  Verificando endereços de escuta..."
if [ -f /etc/postgresql/*/main/postgresql.conf ]; then
    LISTEN_ADDRESSES=$(grep "^listen_addresses" /etc/postgresql/*/main/postgresql.conf | grep -v "^#" | awk '{print $3}' | tr -d "'")
    if [ -z "$LISTEN_ADDRESSES" ]; then
        LISTEN_ADDRESSES="localhost"
    fi
    print_info "listen_addresses = $LISTEN_ADDRESSES"
    if [[ "$LISTEN_ADDRESSES" == *"localhost"* ]] || [[ "$LISTEN_ADDRESSES" == *"*"* ]]; then
        print_success "PostgreSQL está configurado para escutar em localhost ou todas as interfaces"
    else
        print_warning "PostgreSQL pode não estar escutando em localhost"
    fi
fi
echo ""

# 5. Testar conexão local
print_info "5️⃣  Testando conexão local com usuário postgres..."
if sudo -u postgres psql -c "SELECT version();" > /dev/null 2>&1; then
    print_success "Conexão local funcionou!"
    sudo -u postgres psql -c "SELECT version();" | head -n 1
else
    print_error "Conexão local falhou!"
fi
echo ""

# 6. Verificar se o banco dbrief existe
print_info "6️⃣  Verificando se o banco 'dbrief' existe..."
if sudo -u postgres psql -lqt | cut -d \| -f 1 | grep -qw dbrief; then
    print_success "Banco 'dbrief' existe"
else
    print_warning "Banco 'dbrief' NÃO existe"
    print_info "Criando banco 'dbrief'..."
    sudo -u postgres psql -c "CREATE DATABASE dbrief;" 2>/dev/null && print_success "Banco criado" || print_error "Erro ao criar banco"
fi
echo ""

# 7. Verificar usuário postgres e senha
print_info "7️⃣  Testando conexão com usuário 'postgres' e senha '<redacted-db-password>'..."
export PGPASSWORD='<redacted-db-password>'
if psql -h localhost -U postgres -d dbrief -c "SELECT 1;" > /dev/null 2>&1; then
    print_success "Conexão com usuário 'postgres' funcionou!"
else
    print_error "Conexão com usuário 'postgres' falhou!"
    print_info "Verificando se a senha está correta..."
    print_info "Você pode precisar atualizar a senha:"
    echo "sudo -u postgres psql -c \"ALTER USER postgres WITH PASSWORD '<redacted-db-password>';\""
fi
unset PGPASSWORD
echo ""

# 8. Verificar pg_hba.conf
print_info "8️⃣  Verificando pg_hba.conf (métodos de autenticação)..."
if [ -f /etc/postgresql/*/main/pg_hba.conf ]; then
    print_info "Regras de autenticação para localhost:"
    grep -E "^local|^host.*127.0.0.1|^host.*::1" /etc/postgresql/*/main/pg_hba.conf | grep -v "^#" || print_warning "Nenhuma regra encontrada"
fi
echo ""

# 9. Testar conexão do container Docker
print_info "9️⃣  Testando conexão do container backend..."
if docker ps | grep -q debrief-backend; then
    print_info "Container backend encontrado"
    if docker exec debrief-backend python3 -c "
import psycopg2
try:
    conn = psycopg2.connect(
        host='localhost',
        port=5432,
        user='postgres',
        password='<redacted-db-password>',
        database='dbrief'
    )
    print('✅ Conexão do container funcionou!')
    conn.close()
except Exception as e:
    print(f'❌ Erro: {e}')
" 2>&1; then
        print_success "Conexão do container funcionou!"
    else
        print_error "Conexão do container falhou!"
    fi
else
    print_warning "Container backend não encontrado"
fi
echo ""

# 10. Resumo e recomendações
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
print_info "📋 RESUMO E RECOMENDAÇÕES:"
echo ""
print_info "Se PostgreSQL não está acessível:"
echo "  1. Verificar se está rodando: sudo systemctl status postgresql"
echo "  2. Iniciar se necessário: sudo systemctl start postgresql"
echo "  3. Verificar porta: sudo netstat -tlnp | grep 5432"
echo "  4. Verificar listen_addresses em postgresql.conf"
echo "  5. Verificar pg_hba.conf para autenticação"
echo ""
print_info "Se a senha está incorreta:"
echo "  sudo -u postgres psql -c \"ALTER USER postgres WITH PASSWORD '<redacted-db-password>';\""
echo ""
print_info "Se o banco não existe:"
echo "  sudo -u postgres psql -c \"CREATE DATABASE dbrief;\""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

