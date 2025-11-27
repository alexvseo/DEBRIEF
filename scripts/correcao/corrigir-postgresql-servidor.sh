#!/bin/bash

################################################################################
# Script para corrigir problemas de conexão PostgreSQL no servidor
# Configura PostgreSQL para aceitar conexões do backend
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

echo "🔧 Corrigindo configuração PostgreSQL no servidor..."
echo ""

# Configurações
DB_USER="postgres"
DB_PASSWORD="<redacted-db-password>"
DB_NAME="dbrief"
DB_PORT="5432"

# 1. Verificar se PostgreSQL está rodando
print_info "1️⃣  Verificando se PostgreSQL está rodando..."
if ! systemctl is-active --quiet postgresql && ! systemctl is-active --quiet postgresql@*-main; then
    print_warning "PostgreSQL não está rodando. Iniciando..."
    sudo systemctl start postgresql || sudo systemctl start postgresql@*-main || {
        print_error "Não foi possível iniciar PostgreSQL"
        exit 1
    }
    sleep 3
fi
print_success "PostgreSQL está rodando"
echo ""

# 2. Encontrar arquivo postgresql.conf
print_info "2️⃣  Localizando postgresql.conf..."
POSTGRESQL_CONF=$(find /etc/postgresql -name "postgresql.conf" -type f 2>/dev/null | head -n1)
if [ -z "$POSTGRESQL_CONF" ]; then
    print_error "postgresql.conf não encontrado!"
    exit 1
fi
print_success "Encontrado: $POSTGRESQL_CONF"
echo ""

# 3. Configurar listen_addresses
print_info "3️⃣  Configurando listen_addresses..."
if grep -q "^listen_addresses" "$POSTGRESQL_CONF"; then
    # Atualizar existente
    sudo sed -i "s/^listen_addresses.*/listen_addresses = 'localhost'/" "$POSTGRESQL_CONF"
    print_success "listen_addresses atualizado para 'localhost'"
else
    # Adicionar novo
    echo "listen_addresses = 'localhost'" | sudo tee -a "$POSTGRESQL_CONF" > /dev/null
    print_success "listen_addresses adicionado"
fi
echo ""

# 4. Encontrar e configurar pg_hba.conf
print_info "4️⃣  Configurando pg_hba.conf..."
PG_HBA_CONF=$(find /etc/postgresql -name "pg_hba.conf" -type f 2>/dev/null | head -n1)
if [ -z "$PG_HBA_CONF" ]; then
    print_error "pg_hba.conf não encontrado!"
    exit 1
fi
print_success "Encontrado: $PG_HBA_CONF"

# Backup do pg_hba.conf
sudo cp "$PG_HBA_CONF" "${PG_HBA_CONF}.backup.$(date +%Y%m%d_%H%M%S)"
print_info "Backup criado: ${PG_HBA_CONF}.backup.*"

# Adicionar regra para localhost se não existir
if ! grep -q "^host.*127.0.0.1.*md5" "$PG_HBA_CONF"; then
    echo "host    all             all             127.0.0.1/32            md5" | sudo tee -a "$PG_HBA_CONF" > /dev/null
    print_success "Regra para 127.0.0.1 adicionada"
fi

if ! grep -q "^host.*::1.*md5" "$PG_HBA_CONF"; then
    echo "host    all             all             ::1/128                 md5" | sudo tee -a "$PG_HBA_CONF" > /dev/null
    print_success "Regra para ::1 (IPv6) adicionada"
fi
echo ""

# 5. Criar/atualizar usuário postgres
print_info "5️⃣  Criando/atualizando usuário '$DB_USER'..."
sudo -u postgres psql -c "DO \$\$ BEGIN IF NOT EXISTS (SELECT FROM pg_catalog.pg_roles WHERE rolname = '$DB_USER') THEN CREATE ROLE $DB_USER WITH LOGIN PASSWORD '$DB_PASSWORD'; ELSE ALTER ROLE $DB_USER WITH PASSWORD '$DB_PASSWORD'; END IF; END \$\$;" > /dev/null 2>&1
if [ $? -eq 0 ]; then
    print_success "Usuário '$DB_USER' configurado"
else
    print_warning "Erro ao configurar usuário (pode já existir)"
fi
echo ""

# 6. Criar banco de dados
print_info "6️⃣  Criando banco de dados '$DB_NAME'..."
sudo -u postgres psql -c "CREATE DATABASE $DB_NAME OWNER $DB_USER;" > /dev/null 2>&1 || print_warning "Banco pode já existir"
print_success "Banco '$DB_NAME' verificado"
echo ""

# 7. Reiniciar PostgreSQL
print_info "7️⃣  Reiniciando PostgreSQL para aplicar mudanças..."
sudo systemctl restart postgresql || sudo systemctl restart postgresql@*-main || {
    print_error "Erro ao reiniciar PostgreSQL"
    exit 1
}
sleep 3
print_success "PostgreSQL reiniciado"
echo ""

# 8. Testar conexão
print_info "8️⃣  Testando conexão..."
export PGPASSWORD="$DB_PASSWORD"
if psql -h localhost -U "$DB_USER" -d "$DB_NAME" -c "SELECT 1;" > /dev/null 2>&1; then
    print_success "✅ Conexão testada com sucesso!"
else
    print_error "❌ Conexão ainda falhando"
    print_info "Verifique os logs: sudo journalctl -u postgresql -n 50"
fi
unset PGPASSWORD
echo ""

# 9. Testar do container Docker
print_info "9️⃣  Testando conexão do container backend..."
if docker ps | grep -q debrief-backend; then
    sleep 2
    if docker exec debrief-backend python3 -c "
import psycopg2
try:
    conn = psycopg2.connect(
        host='localhost',
        port=5432,
        user='postgres',
        password='$DB_PASSWORD',
        database='dbrief'
    )
    print('✅ Conexão do container funcionou!')
    conn.close()
except Exception as e:
    print(f'❌ Erro: {e}')
" 2>&1 | grep -q "✅"; then
        print_success "Conexão do container funcionou!"
    else
        print_warning "Conexão do container ainda com problemas"
        print_info "Reinicie o container: docker-compose restart backend"
    fi
else
    print_warning "Container backend não encontrado"
fi
echo ""

print_success "🎉 Configuração concluída!"
print_info "Se ainda houver problemas, reinicie o container backend:"
echo "  docker-compose restart backend"
echo ""

