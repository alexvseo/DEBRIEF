#!/bin/bash

# Script para Criar Usuário Admin no Banco de Dados
# Execute no servidor: ./criar-usuario-admin.sh

echo "=========================================="
echo "👤 CRIAR USUÁRIO ADMIN"
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

# Credenciais padrão do admin
ADMIN_USERNAME="admin"
ADMIN_EMAIL="admin@debrief.com"
ADMIN_PASSWORD="admin123"
ADMIN_NOME="Administrador"

echo "Configurações:"
echo "  Username: $ADMIN_USERNAME"
echo "  Email: $ADMIN_EMAIL"
echo "  Senha: $ADMIN_PASSWORD"
echo "  Nome: $ADMIN_NOME"
echo ""

read -p "Deseja usar essas credenciais? (s/N): " USE_DEFAULT
if [ "$USE_DEFAULT" != "s" ] && [ "$USE_DEFAULT" != "S" ]; then
    read -p "Digite o username do admin: " ADMIN_USERNAME
    read -p "Digite o email do admin: " ADMIN_EMAIL
    read -p "Digite a senha do admin: " ADMIN_PASSWORD
    read -p "Digite o nome do admin: " ADMIN_NOME
fi
echo ""

# 1. Verificar conexão com banco
print_info "1️⃣  Verificando conexão com banco de dados..."
export PGPASSWORD="$DB_PASS"
if ! psql -h localhost -p 5432 -U "$DB_USER" -d "$DB_NAME" -c "SELECT 1;" > /dev/null 2>&1; then
    print_error "Não foi possível conectar ao banco de dados"
    exit 1
fi
print_success "Conexão com banco estabelecida"
unset PGPASSWORD
echo ""

# 2. Verificar se tabela users existe
print_info "2️⃣  Verificando se tabela users existe..."
export PGPASSWORD="$DB_PASS"
TABLE_EXISTS=$(psql -h localhost -p 5432 -U "$DB_USER" -d "$DB_NAME" -tAc "SELECT EXISTS (SELECT FROM information_schema.tables WHERE table_schema = 'public' AND table_name = 'users');" 2>/dev/null)
unset PGPASSWORD

if [ "$TABLE_EXISTS" = "t" ]; then
    print_success "Tabela users existe"
else
    print_warning "Tabela users não existe"
    print_info "A tabela será criada quando o backend iniciar pela primeira vez"
    print_info "Ou execute: docker-compose -f docker-compose.host-network.yml restart backend"
    echo ""
    read -p "Deseja aguardar backend criar tabelas? (s/N): " WAIT_BACKEND
    if [ "$WAIT_BACKEND" = "s" ] || [ "$WAIT_BACKEND" = "S" ]; then
        print_info "Aguardando backend criar tabelas..."
        sleep 10
        TABLE_EXISTS=$(psql -h localhost -p 5432 -U "$DB_USER" -d "$DB_NAME" -tAc "SELECT EXISTS (SELECT FROM information_schema.tables WHERE table_schema = 'public' AND table_name = 'users');" 2>/dev/null)
        if [ "$TABLE_EXISTS" = "t" ]; then
            print_success "Tabela users criada"
        else
            print_error "Tabela ainda não existe. Verifique se backend está rodando."
            exit 1
        fi
    else
        exit 1
    fi
fi
echo ""

# 3. Verificar se usuário admin já existe
print_info "3️⃣  Verificando se usuário admin já existe..."
export PGPASSWORD="$DB_PASS"
USER_EXISTS_EMAIL=$(psql -h localhost -p 5432 -U "$DB_USER" -d "$DB_NAME" -tAc "SELECT EXISTS (SELECT FROM users WHERE email = '$ADMIN_EMAIL');" 2>/dev/null)
USER_EXISTS_USERNAME=$(psql -h localhost -p 5432 -U "$DB_USER" -d "$DB_NAME" -tAc "SELECT EXISTS (SELECT FROM users WHERE username = '$ADMIN_USERNAME');" 2>/dev/null)
unset PGPASSWORD

if [ "$USER_EXISTS_EMAIL" = "t" ] || [ "$USER_EXISTS_USERNAME" = "t" ]; then
    if [ "$USER_EXISTS_EMAIL" = "t" ]; then
        print_warning "Usuário com email '$ADMIN_EMAIL' já existe"
    fi
    if [ "$USER_EXISTS_USERNAME" = "t" ]; then
        print_warning "Usuário com username '$ADMIN_USERNAME' já existe"
    fi
    read -p "Deseja atualizar a senha? (s/N): " UPDATE_PASSWORD
    if [ "$UPDATE_PASSWORD" != "s" ] && [ "$UPDATE_PASSWORD" != "S" ]; then
        print_info "Operação cancelada"
        exit 0
    fi
    UPDATE_USER=true
else
    UPDATE_USER=false
fi
echo ""

# 4. Criar hash da senha (usando Python)
print_info "4️⃣  Gerando hash da senha..."
HASHED_PASSWORD=$(python3 << EOF
from passlib.context import CryptContext
pwd_context = CryptContext(schemes=["bcrypt"], deprecated="auto")
password = "$ADMIN_PASSWORD"
hashed = pwd_context.hash(password)
print(hashed)
EOF
)

if [ -z "$HASHED_PASSWORD" ]; then
    print_error "Erro ao gerar hash da senha"
    print_info "Tentando método alternativo..."
    # Método alternativo usando bcrypt diretamente
    HASHED_PASSWORD=$(python3 << EOF
import bcrypt
password = "$ADMIN_PASSWORD".encode('utf-8')
hashed = bcrypt.hashpw(password, bcrypt.gensalt())
print(hashed.decode('utf-8'))
EOF
)
    
    if [ -z "$HASHED_PASSWORD" ]; then
        print_error "Não foi possível gerar hash da senha"
        print_info "Instale passlib ou bcrypt: pip install passlib[bcrypt]"
        exit 1
    fi
fi
print_success "Hash da senha gerado"
echo ""

# 5. Criar ou atualizar usuário
print_info "5️⃣  Criando/atualizando usuário admin..."
export PGPASSWORD="$DB_PASS"

if [ "$UPDATE_USER" = true ]; then
    # Atualizar usuário existente
    psql -h localhost -p 5432 -U "$DB_USER" -d "$DB_NAME" << EOF 2>&1
UPDATE users 
SET 
    password_hash = '$HASHED_PASSWORD',
    nome_completo = '$ADMIN_NOME',
    tipo = 'master',
    ativo = true,
    updated_at = NOW()
WHERE email = '$ADMIN_EMAIL' OR username = '$ADMIN_USERNAME';
EOF
    
    if [ $? -eq 0 ]; then
        print_success "Usuário atualizado com sucesso"
    else
        print_error "Erro ao atualizar usuário"
        exit 1
    fi
else
    # Criar novo usuário
    psql -h localhost -p 5432 -U "$DB_USER" -d "$DB_NAME" << EOF 2>&1
INSERT INTO users (
    id,
    username,
    email,
    password_hash,
    nome_completo,
    tipo,
    ativo,
    cliente_id,
    created_at,
    updated_at
) VALUES (
    gen_random_uuid(),
    '$ADMIN_USERNAME',
    '$ADMIN_EMAIL',
    '$HASHED_PASSWORD',
    '$ADMIN_NOME',
    'master',
    true,
    NULL,
    NOW(),
    NOW()
);
EOF
    
    if [ $? -eq 0 ]; then
        print_success "Usuário criado com sucesso"
    else
        print_error "Erro ao criar usuário"
        exit 1
    fi
fi

unset PGPASSWORD
echo ""

# 6. Verificar usuário criado
print_info "6️⃣  Verificando usuário criado..."
export PGPASSWORD="$DB_PASS"
psql -h localhost -p 5432 -U "$DB_USER" -d "$DB_NAME" -c "SELECT id, username, email, nome_completo, tipo, ativo, created_at FROM users WHERE email = '$ADMIN_EMAIL' OR username = '$ADMIN_USERNAME';" 2>&1 | head -5
unset PGPASSWORD
echo ""

# 7. Resumo
echo "=========================================="
print_success "✅ Usuário admin criado/atualizado!"
echo "=========================================="
echo ""
print_info "Credenciais de acesso:"
echo "  Username: $ADMIN_USERNAME"
echo "  Email: $ADMIN_EMAIL"
echo "  Senha: $ADMIN_PASSWORD"
echo ""
print_warning "⚠️  IMPORTANTE: Use o USERNAME para fazer login, não o email!"
echo ""
print_info "Acesse a aplicação:"
echo "  🌐 http://82.25.92.217:2022/login"
echo ""
print_warning "⚠️  IMPORTANTE: Altere a senha após o primeiro login!"
echo ""

