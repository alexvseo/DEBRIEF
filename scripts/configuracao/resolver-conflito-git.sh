#!/bin/bash

# Script para Resolver Conflitos Git - DeBrief
# Resolve conflitos de merge no servidor
# Execute: ./resolver-conflito-git.sh

set -e

# Cores
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

echo "=========================================="
echo "🔧 RESOLVER CONFLITOS GIT - DeBrief"
echo "=========================================="
echo ""

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

# 1. Verificar status do Git
print_info "1️⃣  Verificando status do Git..."
git status
echo ""

# 2. Verificar mudanças locais
print_info "2️⃣  Verificando mudanças locais..."
CHANGED_FILES=$(git diff --name-only)
if [ -n "$CHANGED_FILES" ]; then
    print_warning "Arquivos modificados localmente:"
    echo "$CHANGED_FILES"
    echo ""
    
    # 3. Mostrar diferenças
    print_info "3️⃣  Diferenças nos arquivos modificados:"
    git diff docker-compose.yml | head -30
    echo ""
    
    # 4. Opções para resolver
    echo "=========================================="
    echo "Escolha uma opção:"
    echo "1) Descartar mudanças locais e usar versão remota (RECOMENDADO)"
    echo "2) Fazer stash das mudanças locais"
    echo "3) Fazer commit das mudanças locais"
    echo "4) Cancelar"
    echo ""
    read -p "Opção (1-4): " option
    
    case $option in
        1)
            print_info "Descartando mudanças locais..."
            git checkout -- docker-compose.yml
            git reset --hard HEAD
            print_success "Mudanças locais descartadas"
            ;;
        2)
            print_info "Fazendo stash das mudanças locais..."
            git stash push -m "Stash antes do pull - $(date)"
            print_success "Mudanças salvas no stash"
            ;;
        3)
            print_info "Fazendo commit das mudanças locais..."
            git add docker-compose.yml
            git commit -m "chore: Mudanças locais no docker-compose.yml"
            print_success "Mudanças commitadas"
            ;;
        4)
            print_info "Operação cancelada"
            exit 0
            ;;
        *)
            print_error "Opção inválida"
            exit 1
            ;;
    esac
else
    print_success "Nenhuma mudança local encontrada"
fi

echo ""

# 5. Fazer pull
print_info "4️⃣  Fazendo pull do repositório..."
if git pull; then
    print_success "Pull realizado com sucesso"
else
    print_error "Erro ao fazer pull"
    print_info "Tente resolver manualmente:"
    echo "   git stash"
    echo "   git pull"
    echo "   git stash pop"
    exit 1
fi

echo ""

# 6. Verificar status final
print_info "5️⃣  Status final do Git..."
git status
echo ""

echo "=========================================="
print_success "Conflitos resolvidos!"
echo "=========================================="
echo ""
print_info "Próximos passos:"
echo "   1. Execute: ./rebuild-completo.sh"
echo "   2. Ou: docker-compose build --no-cache"
echo "   3. Depois: docker-compose up -d"
echo ""

