#!/bin/bash

################################################################################
# Script para verificar rotas registradas no backend
# Lista todas as rotas disponíveis
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

echo "🔍 Verificando rotas do backend..."
echo ""

# Verificar se container está rodando
if ! docker ps | grep -q debrief-backend; then
    print_error "Container backend não está rodando!"
    exit 1
fi

print_info "Listando todas as rotas registradas no backend:"
echo ""

docker exec debrief-backend python3 << 'PYTHON_SCRIPT'
from app.main import app

print("=" * 60)
print("ROTAS REGISTRADAS NO BACKEND")
print("=" * 60)
print()

routes = []
for route in app.routes:
    if hasattr(route, 'path') and hasattr(route, 'methods'):
        methods = ', '.join(sorted(route.methods - {'HEAD', 'OPTIONS'}))
        routes.append((route.path, methods))

# Ordenar por path
routes.sort(key=lambda x: x[0])

# Agrupar por prefixo
current_prefix = None
for path, methods in routes:
    # Extrair prefixo (primeira parte do path)
    prefix = path.split('/')[1] if len(path.split('/')) > 1 else ''
    
    if prefix != current_prefix:
        if current_prefix is not None:
            print()
        print(f"📁 /{prefix}/")
        current_prefix = prefix
    
    # Destacar rotas de clientes
    if 'cliente' in path.lower():
        print(f"  ✅ {methods:15} {path}")
    else:
        print(f"     {methods:15} {path}")

print()
print("=" * 60)
print(f"Total de rotas: {len(routes)}")
print("=" * 60)

# Verificar especificamente rotas de clientes
cliente_routes = [r for r in routes if 'cliente' in r[0].lower()]
if cliente_routes:
    print()
    print("✅ Rotas de clientes encontradas:")
    for path, methods in cliente_routes:
        print(f"   {methods:15} {path}")
else:
    print()
    print("❌ Nenhuma rota de clientes encontrada!")
PYTHON_SCRIPT

echo ""
print_info "Para testar uma rota específica:"
echo "  curl -X GET http://localhost:8000/api/clientes/ -H 'Authorization: Bearer <token>'"
echo ""

