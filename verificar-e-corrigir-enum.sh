#!/bin/bash

# Script para Verificar e Corrigir Enum do Tipo de Usuário
# Execute no servidor: ./verificar-e-corrigir-enum.sh

echo "=========================================="
echo "🔍 VERIFICAR E CORRIGIR ENUM"
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
DB_PASS="Mslestrategia.2025@"

# 1. Verificar valores do enum no banco
print_info "1️⃣  Verificando valores do enum tipousuario no banco..."
export PGPASSWORD="$DB_PASS"
ENUM_VALUES=$(psql -h localhost -p 5432 -U "$DB_USER" -d "$DB_NAME" -tAc "SELECT unnest(enum_range(NULL::tipousuario));" 2>/dev/null || echo "")
unset PGPASSWORD

if [ -n "$ENUM_VALUES" ]; then
    print_info "Valores do enum encontrados:"
    echo "$ENUM_VALUES" | while read value; do
        echo "  - $value"
    done
    
    # Verificar se tem MASTER ou master
    if echo "$ENUM_VALUES" | grep -qi "MASTER"; then
        print_success "Enum tem valor MASTER (maiúsculo)"
        HAS_MASTER_UPPER=true
    else
        print_warning "Enum NÃO tem valor MASTER (maiúsculo)"
        HAS_MASTER_UPPER=false
    fi
    
    if echo "$ENUM_VALUES" | grep -qi "^master$"; then
        print_warning "Enum tem valor master (minúsculo)"
        HAS_MASTER_LOWER=true
    else
        print_info "Enum NÃO tem valor master (minúsculo)"
        HAS_MASTER_LOWER=false
    fi
else
    print_error "Não foi possível verificar valores do enum"
    exit 1
fi
echo ""

# 2. Verificar usuários com valores incorretos
print_info "2️⃣  Verificando usuários com valores incorretos..."
export PGPASSWORD="$DB_PASS"
USERS_WITH_MASTER=$(psql -h localhost -p 5432 -U "$DB_USER" -d "$DB_NAME" -tAc "SELECT COUNT(*) FROM users WHERE tipo::text = 'master';" 2>/dev/null || echo "0")
unset PGPASSWORD

if [ "$USERS_WITH_MASTER" -gt 0 ]; then
    print_warning "Encontrados $USERS_WITH_MASTER usuário(s) com tipo 'master' (minúsculo)"
    
    if [ "$HAS_MASTER_UPPER" = true ]; then
        print_info "Atualizando 'master' para 'MASTER'..."
        export PGPASSWORD="$DB_PASS"
        psql -h localhost -p 5432 -U "$DB_USER" -d "$DB_NAME" << EOF 2>&1
-- Primeiro, alterar temporariamente para texto
ALTER TABLE users ALTER COLUMN tipo TYPE text;
-- Atualizar valores
UPDATE users SET tipo = 'MASTER' WHERE tipo = 'master';
UPDATE users SET tipo = 'CLIENTE' WHERE tipo = 'cliente';
-- Alterar de volta para enum
ALTER TABLE users ALTER COLUMN tipo TYPE tipousuario USING tipo::tipousuario;
EOF
        UPDATE_RESULT=$?
        unset PGPASSWORD
        
        if [ $UPDATE_RESULT -eq 0 ]; then
            print_success "Usuários atualizados com sucesso"
        else
            print_error "Erro ao atualizar usuários"
            print_info "Tentando método alternativo..."
            
            # Método alternativo: usar ALTER TYPE
            export PGPASSWORD="$DB_PASS"
            psql -h localhost -p 5432 -U "$DB_USER" -d "$DB_NAME" << EOF 2>&1
-- Adicionar novo valor ao enum se não existir
DO \$\$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_enum WHERE enumlabel = 'MASTER' AND enumtypid = 'tipousuario'::regtype) THEN
        ALTER TYPE tipousuario ADD VALUE 'MASTER';
    END IF;
END
\$\$;

-- Atualizar usando CAST
UPDATE users SET tipo = 'MASTER'::tipousuario WHERE tipo::text = 'master';
EOF
            unset PGPASSWORD
            print_success "Tentativa de atualização concluída"
        fi
    else
        print_error "Enum não tem valor MASTER, precisa adicionar"
        print_info "Adicionando valor MASTER ao enum..."
        export PGPASSWORD="$DB_PASS"
        psql -h localhost -p 5432 -U "$DB_USER" -d "$DB_NAME" -c "ALTER TYPE tipousuario ADD VALUE IF NOT EXISTS 'MASTER';" 2>&1
        unset PGPASSWORD
        
        # Tentar atualizar novamente
        export PGPASSWORD="$DB_PASS"
        psql -h localhost -p 5432 -U "$DB_USER" -d "$DB_NAME" -c "UPDATE users SET tipo = 'MASTER'::tipousuario WHERE tipo::text = 'master';" 2>&1
        unset PGPASSWORD
    fi
else
    print_success "Nenhum usuário com tipo 'master' (minúsculo) encontrado"
fi
echo ""

# 3. Verificar resultado
print_info "3️⃣  Verificando resultado..."
export PGPASSWORD="$DB_PASS"
ADMIN_INFO=$(psql -h localhost -p 5432 -U "$DB_USER" -d "$DB_NAME" -c "SELECT id, username, email, tipo, ativo FROM users WHERE username = 'admin';" 2>&1)
unset PGPASSWORD

if echo "$ADMIN_INFO" | grep -q "admin"; then
    print_success "Usuário admin encontrado:"
    echo "$ADMIN_INFO" | grep -A 1 "admin"
    
    ADMIN_TIPO=$(echo "$ADMIN_INFO" | grep "admin" | awk '{print $4}' | head -1)
    if [ "$ADMIN_TIPO" = "MASTER" ]; then
        print_success "Tipo do admin está correto: MASTER"
    else
        print_warning "Tipo do admin: $ADMIN_TIPO"
    fi
else
    print_error "Usuário admin não encontrado"
fi
echo ""

# 4. Resumo
echo "=========================================="
print_success "✅ Verificação e correção concluídas!"
echo "=========================================="
echo ""
print_info "Próximos passos:"
echo "  1. Reiniciar backend: docker-compose -f docker-compose.host-network.yml restart backend"
echo "  2. Testar login: curl -X POST http://localhost:2022/api/auth/login -H 'Content-Type: application/x-www-form-urlencoded' -d 'username=admin&password=admin123'"
echo ""

