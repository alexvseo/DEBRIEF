#!/bin/bash

# Script para Verificar Erro 500 no Login
# Execute no servidor: ./verificar-erro-500-login.sh

echo "=========================================="
echo "🔍 VERIFICAR ERRO 500 NO LOGIN"
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

# 1. Testar login e capturar resposta completa
print_info "1️⃣  Testando login e capturando resposta completa..."
LOGIN_RESPONSE=$(curl -s -X POST http://localhost:8000/api/auth/login \
    -H "Content-Type: application/x-www-form-urlencoded" \
    -d "username=admin&password=admin123" 2>&1)

LOGIN_STATUS=$(echo "$LOGIN_RESPONSE" | grep -oP 'HTTP/\d\.\d \K\d+' || echo "000")
if [ "$LOGIN_STATUS" = "200" ]; then
    print_success "Login funciona (HTTP 200)"
    echo "$LOGIN_RESPONSE" | tail -5
elif [ "$LOGIN_STATUS" = "500" ]; then
    print_error "Erro 500 no login"
    echo ""
    print_info "Resposta completa:"
    echo "$LOGIN_RESPONSE"
else
    print_warning "Status HTTP $LOGIN_STATUS"
    echo "$LOGIN_RESPONSE"
fi
echo ""

# 2. Verificar logs do backend em tempo real
print_info "2️⃣  Verificando logs do backend (últimas 30 linhas)..."
echo "----------------------------------------"
docker-compose -f docker-compose.host-network.yml logs --tail=30 backend 2>&1
echo ""

# 3. Verificar se usuário admin existe e está correto
print_info "3️⃣  Verificando usuário admin no banco..."
export PGPASSWORD="Mslestrategia.2025@"
USER_INFO=$(psql -h localhost -p 5432 -U postgres -d dbrief -c "SELECT id, username, email, tipo, ativo FROM users WHERE username = 'admin' OR email = 'admin@debrief.com';" 2>&1)
unset PGPASSWORD

if echo "$USER_INFO" | grep -q "admin"; then
    print_success "Usuário admin encontrado:"
    echo "$USER_INFO" | grep -A 1 "admin"
    
    # Verificar se está ativo
    if echo "$USER_INFO" | grep -q "t.*admin"; then
        print_success "Usuário está ativo"
    else
        print_error "Usuário NÃO está ativo"
    fi
else
    print_error "Usuário admin não encontrado"
    print_info "Execute: ./criar-usuario-admin.sh"
fi
echo ""

# 4. Testar conexão com banco do backend
print_info "4️⃣  Testando conexão do backend com banco..."
docker exec debrief-backend python3 << EOF 2>&1
import os
import sys
try:
    from app.core.database import engine
    from sqlalchemy import text
    
    with engine.connect() as conn:
        result = conn.execute(text("SELECT 1"))
        print("✅ Backend consegue conectar ao banco")
        sys.exit(0)
except Exception as e:
    print(f"❌ Erro ao conectar ao banco: {e}")
    sys.exit(1)
EOF

DB_CONNECTION=$?
if [ $DB_CONNECTION -eq 0 ]; then
    print_success "Backend consegue conectar ao banco"
else
    print_error "Backend NÃO consegue conectar ao banco"
fi
echo ""

# 5. Verificar variáveis de ambiente do backend
print_info "5️⃣  Verificando variáveis de ambiente do backend..."
docker exec debrief-backend env | grep -E "DATABASE_URL|SECRET_KEY" | head -3
echo ""

# 6. Testar verificação de senha
print_info "6️⃣  Testando verificação de senha do usuário admin..."
docker exec debrief-backend python3 << EOF 2>&1
import sys
try:
    from app.core.database import SessionLocal
    from app.models.user import User
    
    db = SessionLocal()
    user = db.query(User).filter(User.username == "admin").first()
    
    if user:
        print(f"✅ Usuário encontrado: {user.username}")
        print(f"   Email: {user.email}")
        print(f"   Tipo: {user.tipo}")
        print(f"   Ativo: {user.ativo}")
        print(f"   Password hash existe: {bool(user.password_hash)}")
        
        # Testar verificação de senha
        if user.verify_password("admin123"):
            print("✅ Senha 'admin123' está correta")
        else:
            print("❌ Senha 'admin123' está INCORRETA")
            print("   Execute: ./criar-usuario-admin.sh para atualizar senha")
    else:
        print("❌ Usuário admin não encontrado")
        print("   Execute: ./criar-usuario-admin.sh")
    
    db.close()
    sys.exit(0)
except Exception as e:
    print(f"❌ Erro: {e}")
    import traceback
    traceback.print_exc()
    sys.exit(1)
EOF

PASSWORD_TEST=$?
echo ""

# 7. Resumo
echo "=========================================="
echo "📊 RESUMO"
echo "=========================================="
echo ""

if [ "$LOGIN_STATUS" = "200" ]; then
    print_success "✅ Login está funcionando!"
elif [ "$LOGIN_STATUS" = "500" ]; then
    print_error "❌ Erro 500 no login"
    echo ""
    print_info "Possíveis causas:"
    echo "  1. Erro ao conectar ao banco de dados"
    echo "  2. Erro na verificação de senha"
    echo "  3. Erro na criação do token JWT"
    echo "  4. Erro no código do backend"
    echo ""
    print_info "Soluções:"
    echo "  1. Verificar logs acima"
    echo "  2. Verificar conexão com banco: ./testar-usuario-postgres.sh"
    echo "  3. Recriar usuário admin: ./criar-usuario-admin.sh"
    echo "  4. Reiniciar backend: docker-compose -f docker-compose.host-network.yml restart backend"
fi
echo ""

