#!/bin/bash

# Script para Solucionar Problema de Acesso ao Banco
# Execute no servidor: ./solucionar-acesso-banco.sh

echo "=========================================="
echo "🔧 SOLUCIONAR ACESSO AO BANCO"
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

# 1. Configurar banco completo
print_info "1️⃣  Configurando banco de dados completo..."
if [ -f "./configurar-banco-completo.sh" ]; then
    ./configurar-banco-completo.sh
else
    print_warning "Script configurar-banco-completo.sh não encontrado"
    print_info "Verificando PostgreSQL local..."
    ./verificar-postgresql-local.sh
fi
echo ""

# 2. Testar conexão local
print_info "2️⃣  Testando conexão local..."
export PGPASSWORD="<redacted-db-password>"
if psql -h localhost -p 5432 -U root -d dbrief -c "SELECT 1;" > /dev/null 2>&1; then
    print_success "Conexão local funcionou!"
    LOCAL_WORKS=true
else
    print_error "Conexão local falhou"
    LOCAL_WORKS=false
fi
unset PGPASSWORD
echo ""

# 3. Decidir solução
if [ "$LOCAL_WORKS" = true ]; then
    print_success "PostgreSQL está acessível em localhost"
    echo ""
    print_info "Solução recomendada: Usar network_mode: host para o backend"
    echo ""
    read -p "Aplicar solução com network_mode: host? (s/N): " APPLY_SOLUTION
    
    if [ "$APPLY_SOLUTION" = "s" ] || [ "$APPLY_SOLUTION" = "S" ]; then
        print_info "Parando containers atuais..."
        docker-compose down
        
        print_info "Usando docker-compose.host-network.yml..."
        docker-compose -f docker-compose.host-network.yml build --no-cache backend
        docker-compose -f docker-compose.host-network.yml up -d
        
        print_success "Backend iniciado com network_mode: host"
        echo ""
        print_info "Aguardando backend iniciar..."
        sleep 10
        
        print_info "Verificando logs..."
        docker-compose -f docker-compose.host-network.yml logs backend | tail -20
        
        print_info "Verificando status..."
        docker-compose -f docker-compose.host-network.yml ps backend
    else
        print_info "Solução não aplicada. Você pode aplicar manualmente:"
        echo ""
        echo "  docker-compose -f docker-compose.host-network.yml up -d"
    fi
else
    print_error "PostgreSQL não está acessível em localhost"
    echo ""
    print_info "Próximos passos:"
    echo "  1. Verificar se PostgreSQL está rodando: sudo systemctl status postgresql"
    echo "  2. Verificar se banco existe: sudo -u postgres psql -l | grep dbrief"
    echo "  3. Configurar PostgreSQL: ./configurar-postgresql-remoto.sh"
fi
echo ""

