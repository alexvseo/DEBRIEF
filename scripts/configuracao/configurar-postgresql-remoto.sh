#!/bin/bash

# Script para Configurar PostgreSQL para Aceitar Conexões Remotas
# Execute no servidor onde o PostgreSQL está rodando
# ATENÇÃO: Execute como root ou com sudo

echo "=========================================="
echo "🔧 CONFIGURAR POSTGRESQL PARA CONEXÕES REMOTAS"
echo "=========================================="
echo ""
echo "⚠️  ATENÇÃO: Este script modifica configurações do PostgreSQL"
echo "   Certifique-se de que você tem acesso root/sudo"
echo ""
read -p "Pressione ENTER para continuar ou Ctrl+C para cancelar..."

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
    echo "   Instale com: apt-get install postgresql postgresql-contrib"
    exit 1
fi
echo ""

# 2. Encontrar arquivo postgresql.conf
print_info "2️⃣  Localizando postgresql.conf..."
POSTGRESQL_CONF=$(sudo find /etc -name "postgresql.conf" 2>/dev/null | head -1)
if [ -z "$POSTGRESQL_CONF" ]; then
    # Tentar localização padrão
    if [ -f "/etc/postgresql/14/main/postgresql.conf" ]; then
        POSTGRESQL_CONF="/etc/postgresql/14/main/postgresql.conf"
    elif [ -f "/etc/postgresql/13/main/postgresql.conf" ]; then
        POSTGRESQL_CONF="/etc/postgresql/13/main/postgresql.conf"
    elif [ -f "/etc/postgresql/12/main/postgresql.conf" ]; then
        POSTGRESQL_CONF="/etc/postgresql/12/main/postgresql.conf"
    else
        print_error "postgresql.conf não encontrado"
        print_info "Localizações comuns:"
        echo "  - /etc/postgresql/*/main/postgresql.conf"
        echo "  - /var/lib/pgsql/data/postgresql.conf"
        exit 1
    fi
fi

print_success "Arquivo encontrado: $POSTGRESQL_CONF"
echo ""

# 3. Fazer backup
print_info "3️⃣  Fazendo backup do postgresql.conf..."
sudo cp "$POSTGRESQL_CONF" "${POSTGRESQL_CONF}.backup.$(date +%Y%m%d_%H%M%S)"
print_success "Backup criado"
echo ""

# 4. Configurar listen_addresses
print_info "4️⃣  Configurando listen_addresses..."
if sudo grep -q "^listen_addresses" "$POSTGRESQL_CONF"; then
    print_warning "listen_addresses já configurado"
    sudo sed -i "s/^#listen_addresses = 'localhost'/listen_addresses = '*'/" "$POSTGRESQL_CONF"
    sudo sed -i "s/^listen_addresses = 'localhost'/listen_addresses = '*'/" "$POSTGRESQL_CONF"
    print_success "listen_addresses atualizado para '*'"
else
    echo "listen_addresses = '*'" | sudo tee -a "$POSTGRESQL_CONF" > /dev/null
    print_success "listen_addresses adicionado"
fi
echo ""

# 5. Encontrar e configurar pg_hba.conf
print_info "5️⃣  Localizando pg_hba.conf..."
PG_HBA_CONF=$(sudo find /etc -name "pg_hba.conf" 2>/dev/null | head -1)
if [ -z "$PG_HBA_CONF" ]; then
    PG_HBA_DIR=$(dirname "$POSTGRESQL_CONF")
    if [ -f "$PG_HBA_DIR/pg_hba.conf" ]; then
        PG_HBA_CONF="$PG_HBA_DIR/pg_hba.conf"
    else
        print_error "pg_hba.conf não encontrado"
        exit 1
    fi
fi

print_success "Arquivo encontrado: $PG_HBA_CONF"
echo ""

# 6. Fazer backup do pg_hba.conf
print_info "6️⃣  Fazendo backup do pg_hba.conf..."
sudo cp "$PG_HBA_CONF" "${PG_HBA_CONF}.backup.$(date +%Y%m%d_%H%M%S)"
print_success "Backup criado"
echo ""

# 7. Adicionar regra para conexões remotas
print_info "7️⃣  Adicionando regra para conexões remotas..."
if sudo grep -q "host.*all.*all.*0.0.0.0/0.*md5" "$PG_HBA_CONF"; then
    print_warning "Regra para conexões remotas já existe"
else
    echo "host    all             all             0.0.0.0/0               md5" | sudo tee -a "$PG_HBA_CONF" > /dev/null
    print_success "Regra adicionada ao pg_hba.conf"
fi
echo ""

# 8. Verificar firewall
print_info "8️⃣  Verificando firewall..."
if command -v ufw &> /dev/null; then
    if sudo ufw status | grep -q "5432"; then
        print_warning "Porta 5432 já está nas regras do ufw"
    else
        print_info "Adicionando regra do ufw para porta 5432..."
        read -p "Adicionar regra do ufw? (s/N): " ADD_UFW
        if [ "$ADD_UFW" = "s" ] || [ "$ADD_UFW" = "S" ]; then
            sudo ufw allow 5432/tcp
            print_success "Regra do ufw adicionada"
        else
            print_warning "Regra do ufw não adicionada (adicione manualmente se necessário)"
        fi
    fi
else
    print_warning "ufw não encontrado (verifique iptables manualmente)"
fi
echo ""

# 9. Reiniciar PostgreSQL
print_info "9️⃣  Reiniciando PostgreSQL..."
if command -v systemctl &> /dev/null; then
    sudo systemctl restart postgresql
    sleep 2
    if sudo systemctl is-active --quiet postgresql; then
        print_success "PostgreSQL reiniciado com sucesso"
    else
        print_error "Erro ao reiniciar PostgreSQL"
        sudo systemctl status postgresql | head -10
    fi
else
    print_warning "systemctl não encontrado (reinicie PostgreSQL manualmente)"
fi
echo ""

# 10. Resumo
echo "=========================================="
print_success "✅ Configuração concluída!"
echo "=========================================="
echo ""
print_info "Arquivos modificados:"
echo "  - $POSTGRESQL_CONF"
echo "  - $PG_HBA_CONF"
echo ""
print_info "Backups criados:"
echo "  - ${POSTGRESQL_CONF}.backup.*"
echo "  - ${PG_HBA_CONF}.backup.*"
echo ""
print_info "Próximos passos:"
echo "  1. Teste a conexão: ./testar-conexao-banco.sh"
echo "  2. Se ainda não funcionar, verifique logs:"
echo "     sudo tail -f /var/log/postgresql/postgresql-*.log"
echo ""

