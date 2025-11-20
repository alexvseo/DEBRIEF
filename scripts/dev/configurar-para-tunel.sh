#!/bin/bash

################################################################################
# Script para configurar .env.dev para usar túnel SSH (localhost)
################################################################################

set -e

# Cores
GREEN='\033[0;32m'
BLUE='\033[0;34m'
NC='\033[0m'

print_info() {
    echo -e "${BLUE}ℹ️  $1${NC}"
}

print_success() {
    echo -e "${GREEN}✅ $1${NC}"
}

echo "🔧 Configurando .env.dev para usar túnel SSH..."
echo ""

# Backend
if [ -f "backend/.env.dev" ]; then
    # Atualizar DATABASE_URL para localhost
    if grep -q "@82\.25\.92\.217:5432" backend/.env.dev; then
        sed -i.bak 's|@82\.25\.92\.217:5432|@localhost:5432|g' backend/.env.dev
        print_success "backend/.env.dev atualizado para usar localhost:5432"
        rm -f backend/.env.dev.bak
    else
        print_info "backend/.env.dev já está configurado para localhost"
    fi
else
    # Criar arquivo se não existir
    if [ -f "backend/.env.dev.example" ]; then
        cp backend/.env.dev.example backend/.env.dev
        sed -i.bak 's|@82\.25\.92\.217:5432|@localhost:5432|g' backend/.env.dev
        rm -f backend/.env.dev.bak
        print_success "backend/.env.dev criado e configurado para túnel SSH"
    else
        print_info "Criando backend/.env.dev básico..."
        cat > backend/.env.dev << 'EOF'
DATABASE_URL=postgresql://postgres:Mslestrategia.2025%40@localhost:5432/dbrief
SECRET_KEY=dev-secret-key-local-change-me
FRONTEND_URL=http://localhost:5173
ENVIRONMENT=development
DEBUG=True
EOF
        print_success "backend/.env.dev criado"
    fi
fi

# Frontend
if [ ! -f "frontend/.env.dev" ]; then
    if [ -f "frontend/.env.dev.example" ]; then
        cp frontend/.env.dev.example frontend/.env.dev
        print_success "frontend/.env.dev criado"
    else
        cat > frontend/.env.dev << 'EOF'
VITE_API_URL=http://localhost:8000/api
VITE_ENV=development
VITE_DEBUG_MODE=true
EOF
        print_success "frontend/.env.dev criado"
    fi
fi

echo ""
print_success "✅ Configuração concluída!"
echo ""
print_info "Agora você pode iniciar o ambiente:"
echo "  ./scripts/dev/iniciar-dev-local.sh"
echo ""

