#!/bin/bash

# Script para Verificar PostgreSQL Local no Servidor
# Execute no servidor: ./verificar-postgresql-local.sh

echo "=========================================="
echo "🔍 VERIFICAR POSTGRESQL LOCAL"
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

# 1. Verificar se PostgreSQL está instalado
print_info "1️⃣  Verificando se PostgreSQL está instalado..."
if command -v psql &> /dev/null; then
    PSQL_VERSION=$(psql --version)
    print_success "$PSQL_VERSION encontrado"
else
    print_error "PostgreSQL não encontrado"
    print_info "Instale com: apt-get install postgresql postgresql-contrib"
    exit 1
fi
echo ""

# 2. Verificar se PostgreSQL está rodando
print_info "2️⃣  Verificando se PostgreSQL está rodando..."
if systemctl is-active --quiet postgresql; then
    print_success "PostgreSQL está rodando"
    systemctl status postgresql --no-pager | head -5
else
    print_error "PostgreSQL NÃO está rodando"
    print_info "Iniciando PostgreSQL..."
    sudo systemctl start postgresql
    sleep 2
    if systemctl is-active --quiet postgresql; then
        print_success "PostgreSQL iniciado"
    else
        print_error "Erro ao iniciar PostgreSQL"
        exit 1
    fi
fi
echo ""

# 3. Verificar em qual porta está rodando
print_info "3️⃣  Verificando porta do PostgreSQL..."
if sudo netstat -tlnp | grep -q postgres; then
    print_success "PostgreSQL está escutando:"
    sudo netstat -tlnp | grep postgres | head -3
    LISTENING_PORT=$(sudo netstat -tlnp | grep postgres | grep -oP ':\K[0-9]+' | head -1)
    LISTENING_ADDR=$(sudo netstat -tlnp | grep postgres | awk '{print $4}' | head -1 | cut -d: -f1)
    print_info "Porta: $LISTENING_PORT"
    print_info "Endereço: $LISTENING_ADDR"
    
    if [ "$LISTENING_ADDR" = "127.0.0.1" ] || [ "$LISTENING_ADDR" = "::1" ]; then
        print_warning "PostgreSQL está escutando apenas em localhost!"
        print_warning "Precisa configurar para aceitar conexões remotas"
    elif [ "$LISTENING_ADDR" = "0.0.0.0" ] || [ "$LISTENING_ADDR" = "::" ]; then
        print_success "PostgreSQL está escutando em todas as interfaces"
    fi
else
    print_error "PostgreSQL não está escutando em nenhuma porta"
fi
echo ""

# 4. Testar conexão local
print_info "4️⃣  Testando conexão local (localhost)..."
export PGPASSWORD="<redacted-db-password>"
if psql -h localhost -p 5432 -U root -d dbrief -c "SELECT version();" 2>&1 | grep -q "PostgreSQL"; then
    print_success "Conexão local funcionou!"
    psql -h localhost -p 5432 -U root -d dbrief -c "SELECT current_database(), current_user;" 2>&1 | head -3
else
    ERROR=$(psql -h localhost -p 5432 -U root -d dbrief -c "SELECT version();" 2>&1 | tail -1)
    print_error "Conexão local falhou: $ERROR"
fi
unset PGPASSWORD
echo ""

# 5. Testar conexão com IP do servidor
print_info "5️⃣  Testando conexão com IP do servidor (82.25.92.217)..."
export PGPASSWORD="<redacted-db-password>"
if psql -h 82.25.92.217 -p 5432 -U root -d dbrief -c "SELECT version();" 2>&1 | grep -q "PostgreSQL"; then
    print_success "Conexão com IP externo funcionou!"
else
    ERROR=$(psql -h 82.25.92.217 -p 5432 -U root -d dbrief -c "SELECT version();" 2>&1 | tail -1)
    print_error "Conexão com IP externo falhou: $ERROR"
    print_warning "PostgreSQL precisa ser configurado para aceitar conexões remotas"
fi
unset PGPASSWORD
echo ""

# 6. Verificar configuração do PostgreSQL
print_info "6️⃣  Verificando configuração do PostgreSQL..."
POSTGRESQL_CONF=$(sudo find /etc -name "postgresql.conf" 2>/dev/null | head -1)
if [ -n "$POSTGRESQL_CONF" ]; then
    print_success "Arquivo encontrado: $POSTGRESQL_CONF"
    
    # Verificar listen_addresses
    if sudo grep -q "^listen_addresses" "$POSTGRESQL_CONF"; then
        LISTEN_ADDR=$(sudo grep "^listen_addresses" "$POSTGRESQL_CONF" | head -1)
        print_info "listen_addresses: $LISTEN_ADDR"
        if echo "$LISTEN_ADDR" | grep -q "'\*'\|'0.0.0.0'"; then
            print_success "PostgreSQL configurado para aceitar conexões remotas"
        else
            print_warning "PostgreSQL NÃO está configurado para aceitar conexões remotas"
            print_info "Execute: ./configurar-postgresql-remoto.sh"
        fi
    else
        print_warning "listen_addresses não encontrado (usando padrão: localhost)"
        print_info "Execute: ./configurar-postgresql-remoto.sh"
    fi
else
    print_warning "postgresql.conf não encontrado"
fi
echo ""

# 7. Verificar pg_hba.conf
print_info "7️⃣  Verificando pg_hba.conf..."
PG_HBA_CONF=$(sudo find /etc -name "pg_hba.conf" 2>/dev/null | head -1)
if [ -n "$PG_HBA_CONF" ]; then
    print_success "Arquivo encontrado: $PG_HBA_CONF"
    
    # Verificar regras para conexões remotas
    if sudo grep -q "host.*all.*all.*0.0.0.0/0\|host.*all.*all.*::/0" "$PG_HBA_CONF"; then
        print_success "Regra para conexões remotas encontrada"
        sudo grep "host.*all.*all" "$PG_HBA_CONF" | head -3
    else
        print_warning "Nenhuma regra para conexões remotas encontrada"
        print_info "Execute: ./configurar-postgresql-remoto.sh"
    fi
else
    print_warning "pg_hba.conf não encontrado"
fi
echo ""

# 8. Resumo e recomendações
echo "=========================================="
echo "📊 RESUMO E RECOMENDAÇÕES"
echo "=========================================="
echo ""

if systemctl is-active --quiet postgresql && psql -h localhost -p 5432 -U root -d dbrief -c "SELECT 1;" > /dev/null 2>&1; then
    print_success "PostgreSQL está rodando e acessível localmente"
    
    if psql -h 82.25.92.217 -p 5432 -U root -d dbrief -c "SELECT 1;" > /dev/null 2>&1; then
        print_success "PostgreSQL está acessível pelo IP externo"
        print_info "O problema pode ser na rede Docker"
        echo ""
        print_info "Soluções para Docker:"
        echo "  1. Usar network_mode: host no docker-compose.yml"
        echo "  2. Usar localhost em vez de IP externo no DATABASE_URL"
    else
        print_warning "PostgreSQL NÃO está acessível pelo IP externo"
        echo ""
        print_info "Execute: ./configurar-postgresql-remoto.sh"
    fi
else
    print_error "PostgreSQL não está acessível"
    echo ""
    print_info "Verifique:"
    echo "  1. PostgreSQL está rodando: sudo systemctl status postgresql"
    echo "  2. Banco dbrief existe: sudo -u postgres psql -l | grep dbrief"
    echo "  3. Usuário root existe: sudo -u postgres psql -c '\du' | grep root"
fi
echo ""

