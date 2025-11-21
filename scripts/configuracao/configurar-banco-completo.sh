#!/bin/bash

# Script para Configurar Banco de Dados Completo
# Cria usuário, banco e configura PostgreSQL
# Execute no servidor: ./configurar-banco-completo.sh

echo "=========================================="
echo "🔧 CONFIGURAR BANCO DE DADOS COMPLETO"
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

# Configurações
DB_NAME="dbrief"
DB_USER="root"
DB_PASS="Mslestra@2025"

# 1. Verificar se PostgreSQL está rodando
print_info "1️⃣  Verificando PostgreSQL..."
if ! systemctl is-active --quiet postgresql; then
    print_error "PostgreSQL não está rodando"
    print_info "Iniciando PostgreSQL..."
    sudo systemctl start postgresql
    sleep 2
    if systemctl is-active --quiet postgresql; then
        print_success "PostgreSQL iniciado"
    else
        print_error "Erro ao iniciar PostgreSQL"
        exit 1
    fi
else
    print_success "PostgreSQL está rodando"
fi
echo ""

# 2. Verificar se usuário root existe
print_info "2️⃣  Verificando usuário '$DB_USER'..."
if sudo -u postgres psql -tAc "SELECT 1 FROM pg_roles WHERE rolname='$DB_USER'" | grep -q 1; then
    print_success "Usuário '$DB_USER' existe"
    
    # Atualizar senha
    print_info "Atualizando senha do usuário..."
    sudo -u postgres psql -c "ALTER USER $DB_USER WITH PASSWORD '$DB_PASS';" > /dev/null 2>&1
    print_success "Senha atualizada"
else
    print_warning "Usuário '$DB_USER' não existe"
    print_info "Criando usuário '$DB_USER'..."
    sudo -u postgres psql -c "CREATE USER $DB_USER WITH PASSWORD '$DB_PASS';" > /dev/null 2>&1
    sudo -u postgres psql -c "ALTER USER $DB_USER CREATEDB;" > /dev/null 2>&1
    print_success "Usuário '$DB_USER' criado"
fi
echo ""

# 3. Verificar se banco existe
print_info "3️⃣  Verificando banco '$DB_NAME'..."
if sudo -u postgres psql -lqt | cut -d \| -f 1 | grep -qw "$DB_NAME"; then
    print_success "Banco '$DB_NAME' existe"
    
    # Garantir permissões
    print_info "Garantindo permissões..."
    sudo -u postgres psql -c "GRANT ALL PRIVILEGES ON DATABASE $DB_NAME TO $DB_USER;" > /dev/null 2>&1
    print_success "Permissões garantidas"
else
    print_warning "Banco '$DB_NAME' não existe"
    print_info "Criando banco '$DB_NAME'..."
    sudo -u postgres psql -c "CREATE DATABASE $DB_NAME OWNER $DB_USER;" > /dev/null 2>&1
    print_success "Banco '$DB_NAME' criado"
fi
echo ""

# 4. Testar conexão local
print_info "4️⃣  Testando conexão local..."
export PGPASSWORD="$DB_PASS"
if psql -h localhost -p 5432 -U "$DB_USER" -d "$DB_NAME" -c "SELECT 1;" > /dev/null 2>&1; then
    print_success "Conexão local funcionou!"
    psql -h localhost -p 5432 -U "$DB_USER" -d "$DB_NAME" -c "SELECT current_database(), current_user;" 2>&1 | head -3
else
    ERROR=$(psql -h localhost -p 5432 -U "$DB_USER" -d "$DB_NAME" -c "SELECT 1;" 2>&1 | tail -1)
    print_error "Conexão local falhou: $ERROR"
    print_warning "Verificando permissões..."
    
    # Tentar conectar como postgres e dar permissões
    sudo -u postgres psql -d "$DB_NAME" -c "GRANT ALL PRIVILEGES ON DATABASE $DB_NAME TO $DB_USER;" > /dev/null 2>&1
    sudo -u postgres psql -d "$DB_NAME" -c "GRANT ALL ON SCHEMA public TO $DB_USER;" > /dev/null 2>&1
    
    # Testar novamente
    if psql -h localhost -p 5432 -U "$DB_USER" -d "$DB_NAME" -c "SELECT 1;" > /dev/null 2>&1; then
        print_success "Conexão local funcionou após ajustar permissões!"
    else
        print_error "Ainda não funciona. Verifique manualmente."
    fi
fi
unset PGPASSWORD
echo ""

# 5. Configurar PostgreSQL para aceitar conexões remotas
print_info "5️⃣  Configurando PostgreSQL para aceitar conexões remotas..."
if [ -f "./configurar-postgresql-remoto.sh" ]; then
    print_info "Executando configurar-postgresql-remoto.sh..."
    ./configurar-postgresql-remoto.sh
else
    print_warning "Script configurar-postgresql-remoto.sh não encontrado"
    print_info "Configurando manualmente..."
    
    # Encontrar postgresql.conf
    POSTGRESQL_CONF=$(sudo find /etc -name "postgresql.conf" 2>/dev/null | head -1)
    if [ -n "$POSTGRESQL_CONF" ]; then
        print_info "Arquivo encontrado: $POSTGRESQL_CONF"
        
        # Fazer backup
        sudo cp "$POSTGRESQL_CONF" "${POSTGRESQL_CONF}.backup.$(date +%Y%m%d_%H%M%S)"
        
        # Configurar listen_addresses
        if sudo grep -q "^listen_addresses" "$POSTGRESQL_CONF"; then
            sudo sed -i "s/^#listen_addresses = 'localhost'/listen_addresses = '*'/" "$POSTGRESQL_CONF"
            sudo sed -i "s/^listen_addresses = 'localhost'/listen_addresses = '*'/" "$POSTGRESQL_CONF"
        else
            echo "listen_addresses = '*'" | sudo tee -a "$POSTGRESQL_CONF" > /dev/null
        fi
        print_success "listen_addresses configurado"
        
        # Configurar pg_hba.conf
        PG_HBA_CONF=$(dirname "$POSTGRESQL_CONF")/pg_hba.conf
        if [ -f "$PG_HBA_CONF" ]; then
            sudo cp "$PG_HBA_CONF" "${PG_HBA_CONF}.backup.$(date +%Y%m%d_%H%M%S)"
            
            if ! sudo grep -q "host.*all.*all.*0.0.0.0/0.*md5" "$PG_HBA_CONF"; then
                echo "host    all             all             0.0.0.0/0               md5" | sudo tee -a "$PG_HBA_CONF" > /dev/null
                print_success "Regra adicionada ao pg_hba.conf"
            fi
        fi
        
        # Reiniciar PostgreSQL
        print_info "Reiniciando PostgreSQL..."
        sudo systemctl restart postgresql
        sleep 2
        if systemctl is-active --quiet postgresql; then
            print_success "PostgreSQL reiniciado"
        else
            print_error "Erro ao reiniciar PostgreSQL"
        fi
    else
        print_error "postgresql.conf não encontrado"
    fi
fi
echo ""

# 6. Testar conexão final
print_info "6️⃣  Testando conexão final..."
export PGPASSWORD="$DB_PASS"

# Testar localhost
if psql -h localhost -p 5432 -U "$DB_USER" -d "$DB_NAME" -c "SELECT 1;" > /dev/null 2>&1; then
    print_success "✅ Conexão localhost funcionou!"
else
    print_error "❌ Conexão localhost ainda falha"
fi

# Testar IP externo (se configurado)
if psql -h 82.25.92.217 -p 5432 -U "$DB_USER" -d "$DB_NAME" -c "SELECT 1;" > /dev/null 2>&1; then
    print_success "✅ Conexão IP externo funcionou!"
else
    print_warning "⚠️  Conexão IP externo não funciona (pode ser normal se usar network_mode: host)"
fi

unset PGPASSWORD
echo ""

# 7. Resumo
echo "=========================================="
print_success "✅ Configuração concluída!"
echo "=========================================="
echo ""
print_info "Resumo:"
echo "  - Usuário: $DB_USER"
echo "  - Banco: $DB_NAME"
echo "  - Senha: $DB_PASS"
echo "  - Host: localhost:5432"
echo ""
print_info "Para usar com Docker:"
echo "  - Use network_mode: host OU"
echo "  - Use host.docker.internal:5432"
echo ""
print_info "Testar conexão:"
echo "  psql -h localhost -U $DB_USER -d $DB_NAME"
echo ""

