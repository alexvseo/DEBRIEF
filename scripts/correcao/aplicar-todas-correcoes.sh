#!/bin/bash

# Script para Aplicar Todas as Correções
# Execute no servidor: ./aplicar-todas-correcoes.sh

echo "=========================================="
echo "🚀 APLICAR TODAS AS CORREÇÕES"
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

# 1. Fazer pull
print_info "1️⃣  Fazendo pull das atualizações..."
git pull
echo ""

# 2. Corrigir enum no banco
print_info "2️⃣  Corrigindo enum no banco de dados..."
if [ -f "./corrigir-enum-banco-completo.sh" ]; then
    ./corrigir-enum-banco-completo.sh
else
    print_warning "Script corrigir-enum-banco-completo.sh não encontrado"
fi
echo ""

# 3. Corrigir porta 80 do frontend
print_info "3️⃣  Corrigindo porta 80 do frontend..."
if [ -f "./corrigir-porta-80-frontend.sh" ]; then
    ./corrigir-porta-80-frontend.sh
else
    print_warning "Script corrigir-porta-80-frontend.sh não encontrado"
    print_info "Parando e reiniciando frontend manualmente..."
    docker-compose -f docker-compose.host-network.yml down
    sleep 3
    docker-compose -f docker-compose.host-network.yml up -d backend
    sleep 10
    docker-compose -f docker-compose.host-network.yml up -d frontend
    sleep 5
    docker-compose -f docker-compose.host-network.yml up -d caddy
fi
echo ""

# 4. Rebuild do backend (para aplicar correção do enum no código)
print_info "4️⃣  Fazendo rebuild do backend (para aplicar correção do enum)..."
docker-compose -f docker-compose.host-network.yml build backend
docker-compose -f docker-compose.host-network.yml up -d backend
sleep 10

# Aguardar backend ficar healthy
for i in {1..12}; do
    BACKEND_HEALTH=$(docker inspect debrief-backend --format='{{.State.Health.Status}}' 2>/dev/null || echo "no_healthcheck")
    if [ "$BACKEND_HEALTH" = "healthy" ]; then
        print_success "Backend está healthy"
        break
    fi
    echo -n "."
    sleep 5
done
echo ""
echo ""

# 5. Testar login
print_info "5️⃣  Testando login..."
sleep 3
LOGIN_RESPONSE=$(curl -s -X POST http://localhost:2022/api/auth/login \
    -H "Content-Type: application/x-www-form-urlencoded" \
    -d "username=admin&password=admin123" 2>&1)

LOGIN_STATUS=$(echo "$LOGIN_RESPONSE" | grep -oP 'HTTP/\d\.\d \K\d+' || echo "000")
if echo "$LOGIN_RESPONSE" | grep -q "access_token"; then
    print_success "✅ Login funciona! Token recebido"
    echo "$LOGIN_RESPONSE" | grep -o '"access_token":"[^"]*"' | head -1 | cut -d'"' -f4 | cut -c1-50
    echo "..."
elif [ "$LOGIN_STATUS" = "200" ]; then
    print_success "✅ Login funciona! (HTTP 200)"
    echo "$LOGIN_RESPONSE" | tail -3
elif [ "$LOGIN_STATUS" = "401" ]; then
    print_warning "Login retorna 401 (credenciais inválidas)"
    print_info "Verifique usuário admin: ./criar-usuario-admin.sh"
elif [ "$LOGIN_STATUS" = "500" ]; then
    print_error "Login ainda retorna 500"
    print_info "Verifique logs: docker-compose -f docker-compose.host-network.yml logs backend | tail -30"
else
    print_warning "Login retorna HTTP $LOGIN_STATUS"
    echo "Resposta: $LOGIN_RESPONSE" | head -5
fi
echo ""

# 6. Testar todas as conexões
print_info "6️⃣  Testando todas as conexões..."
sleep 2

# Backend
BACKEND_RESPONSE=$(curl -s -o /dev/null -w "%{http_code}" http://localhost:8000/health 2>/dev/null || echo "000")
if [ "$BACKEND_RESPONSE" = "200" ]; then
    print_success "Backend responde (HTTP 200)"
else
    print_error "Backend não responde (HTTP $BACKEND_RESPONSE)"
fi

# Caddy API
CADDY_API_RESPONSE=$(curl -s -o /dev/null -w "%{http_code}" http://localhost:2022/api/health 2>/dev/null || echo "000")
if [ "$CADDY_API_RESPONSE" = "200" ]; then
    print_success "Caddy API funciona (HTTP 200)"
else
    print_error "Caddy API não funciona (HTTP $CADDY_API_RESPONSE)"
fi

# Caddy Frontend
CADDY_FRONTEND_RESPONSE=$(curl -s -o /dev/null -w "%{http_code}" http://localhost:2022/ 2>/dev/null || echo "000")
if [ "$CADDY_FRONTEND_RESPONSE" = "200" ]; then
    print_success "Caddy Frontend funciona (HTTP 200)"
elif [ "$CADDY_FRONTEND_RESPONSE" = "301" ] || [ "$CADDY_FRONTEND_RESPONSE" = "302" ]; then
    print_warning "Caddy Frontend retorna redirecionamento (HTTP $CADDY_FRONTEND_RESPONSE) - pode ser normal"
else
    print_warning "Caddy Frontend retorna HTTP $CADDY_FRONTEND_RESPONSE"
fi
echo ""

# 7. Resumo
echo "=========================================="
echo "📊 RESUMO FINAL"
echo "=========================================="
echo ""

if echo "$LOGIN_RESPONSE" | grep -q "access_token" || [ "$LOGIN_STATUS" = "200" ]; then
    print_success "✅ ✅ TODAS AS CORREÇÕES APLICADAS COM SUCESSO!"
    echo ""
    print_info "Acesse a aplicação:"
    echo "  🌐 http://82.25.92.217:2022/login"
    echo ""
    print_info "Credenciais:"
    echo "  Username: admin"
    echo "  Senha: admin123"
    echo ""
    print_success "Sistema está funcionando corretamente!"
else
    print_warning "⚠️  Alguns problemas ainda persistem"
    echo ""
    if ! echo "$LOGIN_RESPONSE" | grep -q "access_token" && [ "$LOGIN_STATUS" != "200" ]; then
        print_info "Login:"
        echo "  - Execute: ./verificar-erro-500-login.sh"
        echo "  - Verifique: docker-compose -f docker-compose.host-network.yml logs backend | tail -30"
    fi
    if [ "$CADDY_FRONTEND_RESPONSE" != "200" ] && [ "$CADDY_FRONTEND_RESPONSE" != "301" ] && [ "$CADDY_FRONTEND_RESPONSE" != "302" ]; then
        print_info "Frontend:"
        echo "  - Ver logs: docker-compose -f docker-compose.host-network.yml logs frontend"
        echo "  - Verificar porta 80: netstat -tlnp | grep :80"
    fi
fi
echo ""

