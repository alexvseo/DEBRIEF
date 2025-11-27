#!/bin/bash

# Script para Corrigir Enum no Banco de Dados
# Execute no servidor: ./corrigir-enum-banco-completo.sh

echo "=========================================="
echo "🔧 CORRIGIR ENUM NO BANCO DE DADOS"
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
DB_PASS="<redacted-db-password>"

# 1. Verificar valores do enum atual
print_info "1️⃣  Verificando valores do enum tipousuario no banco..."
export PGPASSWORD="$DB_PASS"
ENUM_VALUES=$(psql -h localhost -p 5432 -U "$DB_USER" -d "$DB_NAME" -tAc "SELECT unnest(enum_range(NULL::tipousuario));" 2>/dev/null || echo "")
unset PGPASSWORD

if [ -n "$ENUM_VALUES" ]; then
    print_info "Valores do enum encontrados:"
    echo "$ENUM_VALUES" | while read value; do
        echo "  - $value"
    done
else
    print_error "Não foi possível verificar valores do enum"
    exit 1
fi
echo ""

# 2. Verificar se há valores maiúsculos
HAS_UPPER=false
if echo "$ENUM_VALUES" | grep -q "^MASTER$"; then
    print_warning "Enum tem valor MASTER (maiúsculo) - precisa corrigir"
    HAS_UPPER=true
fi

if echo "$ENUM_VALUES" | grep -q "^CLIENTE$"; then
    print_warning "Enum tem valor CLIENTE (maiúsculo) - precisa corrigir"
    HAS_UPPER=true
fi

# 3. Verificar usuários
print_info "2️⃣  Verificando usuários no banco..."
export PGPASSWORD="$DB_PASS"
USERS_COUNT=$(psql -h localhost -p 5432 -U "$DB_USER" -d "$DB_NAME" -tAc "SELECT COUNT(*) FROM users;" 2>/dev/null || echo "0")
USERS_WITH_MASTER=$(psql -h localhost -p 5432 -U "$DB_USER" -d "$DB_NAME" -tAc "SELECT COUNT(*) FROM users WHERE tipo::text = 'master';" 2>/dev/null || echo "0")
USERS_WITH_MASTER_UPPER=$(psql -h localhost -p 5432 -U "$DB_USER" -d "$DB_NAME" -tAc "SELECT COUNT(*) FROM users WHERE tipo::text = 'MASTER';" 2>/dev/null || echo "0")
unset PGPASSWORD

print_info "Total de usuários: $USERS_COUNT"
print_info "Usuários com tipo 'master' (minúsculo): $USERS_WITH_MASTER"
print_info "Usuários com tipo 'MASTER' (maiúsculo): $USERS_WITH_MASTER_UPPER"
echo ""

# 4. Se o enum tem valores maiúsculos, precisamos corrigir
if [ "$HAS_UPPER" = true ]; then
    print_warning "3️⃣  Enum tem valores maiúsculos, mas banco foi criado com minúsculos"
    print_info "O banco foi criado com 'master' e 'cliente' (minúsculos)"
    print_info "Mas o enum pode ter sido alterado para 'MASTER' e 'CLIENTE' (maiúsculos)"
    print_info "Vamos garantir que o enum tenha apenas valores minúsculos"
    echo ""
    
    # Verificar se podemos adicionar valores minúsculos
    if ! echo "$ENUM_VALUES" | grep -q "^master$"; then
        print_info "Adicionando 'master' ao enum..."
        export PGPASSWORD="$DB_PASS"
        psql -h localhost -p 5432 -U "$DB_USER" -d "$DB_NAME" -c "ALTER TYPE tipousuario ADD VALUE IF NOT EXISTS 'master';" 2>&1
        unset PGPASSWORD
    fi
    
    if ! echo "$ENUM_VALUES" | grep -q "^cliente$"; then
        print_info "Adicionando 'cliente' ao enum..."
        export PGPASSWORD="$DB_PASS"
        psql -h localhost -p 5432 -U "$DB_USER" -d "$DB_NAME" -c "ALTER TYPE tipousuario ADD VALUE IF NOT EXISTS 'cliente';" 2>&1
        unset PGPASSWORD
    fi
    
    # Atualizar usuários que estão com valores maiúsculos
    if [ "$USERS_WITH_MASTER_UPPER" -gt 0 ]; then
        print_info "Atualizando usuários de 'MASTER' para 'master'..."
        export PGPASSWORD="$DB_PASS"
        psql -h localhost -p 5432 -U "$DB_USER" -d "$DB_NAME" << EOF 2>&1
-- Converter coluna temporariamente para text
ALTER TABLE users ALTER COLUMN tipo TYPE text;
-- Atualizar valores
UPDATE users SET tipo = 'master' WHERE tipo = 'MASTER';
UPDATE users SET tipo = 'cliente' WHERE tipo = 'CLIENTE';
-- Converter de volta para enum
ALTER TABLE users ALTER COLUMN tipo TYPE tipousuario USING tipo::tipousuario;
EOF
        UPDATE_RESULT=$?
        unset PGPASSWORD
        
        if [ $UPDATE_RESULT -eq 0 ]; then
            print_success "Usuários atualizados com sucesso"
        else
            print_error "Erro ao atualizar usuários"
        fi
    fi
else
    print_success "3️⃣  Enum já tem valores minúsculos (correto)"
    
    # Verificar se há usuários com valores incorretos
    if [ "$USERS_WITH_MASTER" -eq 0 ] && [ "$USERS_COUNT" -gt 0 ]; then
        print_warning "Nenhum usuário com tipo 'master' encontrado, mas há $USERS_COUNT usuário(s)"
        print_info "Listando tipos de usuários:"
        export PGPASSWORD="$DB_PASS"
        psql -h localhost -p 5432 -U "$DB_USER" -d "$DB_NAME" -c "SELECT tipo, COUNT(*) FROM users GROUP BY tipo;" 2>&1
        unset PGPASSWORD
    fi
fi
echo ""

# 5. Verificar usuário admin
print_info "4️⃣  Verificando usuário admin..."
export PGPASSWORD="$DB_PASS"
ADMIN_INFO=$(psql -h localhost -p 5432 -U "$DB_USER" -d "$DB_NAME" -c "SELECT id, username, email, tipo, ativo FROM users WHERE username = 'admin';" 2>&1)
unset PGPASSWORD

if echo "$ADMIN_INFO" | grep -q "admin"; then
    print_success "Usuário admin encontrado:"
    echo "$ADMIN_INFO" | grep -A 1 "admin"
    
    ADMIN_TIPO=$(echo "$ADMIN_INFO" | grep "admin" | awk '{print $4}' | head -1)
    if [ "$ADMIN_TIPO" = "master" ]; then
        print_success "Tipo do admin está correto: master"
    else
        print_warning "Tipo do admin: $ADMIN_TIPO (esperado: master)"
        
        # Tentar corrigir
        if [ "$ADMIN_TIPO" != "master" ]; then
            print_info "Corrigindo tipo do admin para 'master'..."
            export PGPASSWORD="$DB_PASS"
            psql -h localhost -p 5432 -U "$DB_USER" -d "$DB_NAME" -c "UPDATE users SET tipo = 'master'::tipousuario WHERE username = 'admin';" 2>&1
            unset PGPASSWORD
            print_success "Tipo do admin corrigido"
        fi
    fi
    
    # Verificar se está ativo
    ADMIN_ATIVO=$(echo "$ADMIN_INFO" | grep "admin" | awk '{print $5}' | head -1)
    if [ "$ADMIN_ATIVO" = "t" ] || [ "$ADMIN_ATIVO" = "true" ]; then
        print_success "Admin está ativo"
    else
        print_warning "Admin NÃO está ativo"
        print_info "Ativando admin..."
        export PGPASSWORD="$DB_PASS"
        psql -h localhost -p 5432 -U "$DB_USER" -d "$DB_NAME" -c "UPDATE users SET ativo = true WHERE username = 'admin';" 2>&1
        unset PGPASSWORD
        print_success "Admin ativado"
    fi
else
    print_error "Usuário admin não encontrado"
    print_info "Execute: ./criar-usuario-admin.sh"
fi
echo ""

# 6. Resumo final
print_info "5️⃣  Verificando resultado final..."
export PGPASSWORD="$DB_PASS"
FINAL_ENUM_VALUES=$(psql -h localhost -p 5432 -U "$DB_USER" -d "$DB_NAME" -tAc "SELECT unnest(enum_range(NULL::tipousuario));" 2>/dev/null || echo "")
FINAL_ADMIN=$(psql -h localhost -p 5432 -U "$DB_USER" -d "$DB_NAME" -tAc "SELECT tipo FROM users WHERE username = 'admin';" 2>/dev/null || echo "")
unset PGPASSWORD

print_info "Valores finais do enum:"
echo "$FINAL_ENUM_VALUES" | while read value; do
    echo "  - $value"
done

if [ "$FINAL_ADMIN" = "master" ]; then
    print_success "Admin tem tipo correto: master"
else
    print_warning "Admin tem tipo: $FINAL_ADMIN"
fi
echo ""

# 7. Resumo
echo "=========================================="
print_success "✅ Correção do enum concluída!"
echo "=========================================="
echo ""
print_info "Próximos passos:"
echo "  1. Reiniciar backend: docker-compose -f docker-compose.host-network.yml restart backend"
echo "  2. Testar login: curl -X POST http://localhost:2022/api/auth/login -H 'Content-Type: application/x-www-form-urlencoded' -d 'username=admin&password=admin123'"
echo ""

