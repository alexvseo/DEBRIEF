#!/bin/bash

# Script para Corrigir Enum do Tipo de Usuário no Banco
# Execute no servidor: ./corrigir-enum-usuario.sh

echo "=========================================="
echo "🔧 CORRIGIR ENUM DO TIPO DE USUÁRIO"
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
DB_USER="postgres"
DB_PASS="Mslestra@2025"

# 1. Verificar usuários com tipo 'master' (minúsculo)
print_info "1️⃣  Verificando usuários com tipo 'master' (minúsculo)..."
export PGPASSWORD="$DB_PASS"
USERS_WITH_MASTER=$(psql -h localhost -p 5432 -U "$DB_USER" -d "$DB_NAME" -tAc "SELECT COUNT(*) FROM users WHERE tipo = 'master';" 2>/dev/null || echo "0")
unset PGPASSWORD

if [ "$USERS_WITH_MASTER" -gt 0 ]; then
    print_warning "Encontrados $USERS_WITH_MASTER usuário(s) com tipo 'master' (minúsculo)"
    print_info "Listando usuários:"
    export PGPASSWORD="$DB_PASS"
    psql -h localhost -p 5432 -U "$DB_USER" -d "$DB_NAME" -c "SELECT id, username, email, tipo FROM users WHERE tipo = 'master';" 2>&1 | head -10
    unset PGPASSWORD
else
    print_success "Nenhum usuário com tipo 'master' (minúsculo) encontrado"
fi
echo ""

# 2. Atualizar tipo de 'master' para 'MASTER'
if [ "$USERS_WITH_MASTER" -gt 0 ]; then
    print_info "2️⃣  Atualizando tipo de 'master' para 'MASTER'..."
    export PGPASSWORD="$DB_PASS"
    psql -h localhost -p 5432 -U "$DB_USER" -d "$DB_NAME" << EOF 2>&1
UPDATE users 
SET tipo = 'MASTER'::tipousuario
WHERE tipo = 'master';
EOF
    UPDATE_RESULT=$?
    unset PGPASSWORD
    
    if [ $UPDATE_RESULT -eq 0 ]; then
        print_success "Usuários atualizados com sucesso"
        
        # Verificar novamente
        export PGPASSWORD="$DB_PASS"
        UPDATED_COUNT=$(psql -h localhost -p 5432 -U "$DB_USER" -d "$DB_NAME" -tAc "SELECT COUNT(*) FROM users WHERE tipo = 'MASTER';" 2>/dev/null || echo "0")
        unset PGPASSWORD
        
        print_success "Agora há $UPDATED_COUNT usuário(s) com tipo 'MASTER'"
    else
        print_error "Erro ao atualizar usuários"
    fi
else
    print_info "2️⃣  Pulando atualização (nenhum usuário com 'master' encontrado)"
fi
echo ""

# 3. Verificar se há outros valores incorretos
print_info "3️⃣  Verificando outros valores incorretos no enum..."
export PGPASSWORD="$DB_PASS"
INVALID_TYPES=$(psql -h localhost -p 5432 -U "$DB_USER" -d "$DB_NAME" -tAc "SELECT COUNT(*) FROM users WHERE tipo NOT IN ('MASTER', 'CLIENTE');" 2>/dev/null || echo "0")
unset PGPASSWORD

if [ "$INVALID_TYPES" -gt 0 ]; then
    print_warning "Encontrados $INVALID_TYPES usuário(s) com tipos inválidos"
    export PGPASSWORD="$DB_PASS"
    psql -h localhost -p 5432 -U "$DB_USER" -d "$DB_NAME" -c "SELECT id, username, email, tipo FROM users WHERE tipo NOT IN ('MASTER', 'CLIENTE');" 2>&1 | head -10
    unset PGPASSWORD
else
    print_success "Todos os usuários têm tipos válidos (MASTER ou CLIENTE)"
fi
echo ""

# 4. Verificar usuário admin especificamente
print_info "4️⃣  Verificando usuário admin..."
export PGPASSWORD="$DB_PASS"
ADMIN_INFO=$(psql -h localhost -p 5432 -U "$DB_USER" -d "$DB_NAME" -c "SELECT id, username, email, tipo, ativo FROM users WHERE username = 'admin' OR email = 'admin@debrief.com';" 2>&1)
unset PGPASSWORD

if echo "$ADMIN_INFO" | grep -q "admin"; then
    print_success "Usuário admin encontrado:"
    echo "$ADMIN_INFO" | grep -A 1 "admin"
    
    # Verificar tipo
    ADMIN_TIPO=$(echo "$ADMIN_INFO" | grep "admin" | awk '{print $4}' | head -1)
    if [ "$ADMIN_TIPO" = "MASTER" ]; then
        print_success "Tipo do admin está correto: MASTER"
    else
        print_warning "Tipo do admin: $ADMIN_TIPO (pode precisar ser atualizado)"
    fi
else
    print_error "Usuário admin não encontrado"
    print_info "Execute: ./criar-usuario-admin.sh"
fi
echo ""

# 5. Resumo
echo "=========================================="
print_success "✅ Correção do enum concluída!"
echo "=========================================="
echo ""
print_info "Próximos passos:"
echo "  1. Reiniciar backend: docker-compose -f docker-compose.host-network.yml restart backend"
echo "  2. Testar login: curl -X POST http://localhost:2022/api/auth/login -d 'username=admin&password=admin123'"
echo ""

