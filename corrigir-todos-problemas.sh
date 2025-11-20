#!/bin/bash

# Script para Corrigir Todos os Problemas Encontrados
# Execute no servidor: ./corrigir-todos-problemas.sh

echo "=========================================="
echo "🔧 CORRIGIR TODOS OS PROBLEMAS"
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

# 2. Corrigir enum do tipo de usuário
print_info "2️⃣  Corrigindo enum do tipo de usuário no banco..."
if [ -f "./corrigir-enum-usuario.sh" ]; then
    ./corrigir-enum-usuario.sh
else
    print_warning "Script corrigir-enum-usuario.sh não encontrado"
    print_info "Corrigindo manualmente..."
    export PGPASSWORD="Mslestrategia.2025@"
    psql -h localhost -p 5432 -U postgres -d dbrief -c "UPDATE users SET tipo = 'MASTER'::tipousuario WHERE tipo = 'master';" 2>&1
    unset PGPASSWORD
    print_success "Enum corrigido"
fi
echo ""

# 3. Verificar se porta 80 está em uso
print_info "3️⃣  Verificando se porta 80 está em uso..."
if netstat -tlnp 2>/dev/null | grep -q ":80.*LISTEN" || ss -tlnp 2>/dev/null | grep -q ":80"; then
    print_warning "Porta 80 está em uso"
    print_info "Processo usando porta 80:"
    netstat -tlnp 2>/dev/null | grep ":80" | head -3 || ss -tlnp 2>/dev/null | grep ":80" | head -3
    
    # Verificar se é o frontend
    FRONTEND_PID=$(docker inspect debrief-frontend --format='{{.State.Pid}}' 2>/dev/null || echo "")
    if [ -n "$FRONTEND_PID" ]; then
        print_info "Frontend está rodando (PID: $FRONTEND_PID)"
    else
        print_warning "Frontend não está rodando, mas porta 80 está em uso"
        print_info "Pode haver conflito de porta"
    fi
else
    print_success "Porta 80 está livre"
fi
echo ""

# 4. Verificar logs do frontend
print_info "4️⃣  Verificando logs do frontend (últimas 20 linhas)..."
echo "----------------------------------------"
docker-compose -f docker-compose.host-network.yml logs --tail=20 frontend 2>&1 | tail -20
echo ""

# 5. Parar frontend
print_info "5️⃣  Parando frontend..."
docker-compose -f docker-compose.host-network.yml stop frontend
docker-compose -f docker-compose.host-network.yml rm -f frontend
print_success "Frontend parado"
echo ""

# 6. Aguardar porta 80 ficar livre
print_info "6️⃣  Aguardando porta 80 ficar livre..."
for i in {1..6}; do
    if ! (netstat -tlnp 2>/dev/null | grep -q ":80.*LISTEN" || ss -tlnp 2>/dev/null | grep -q ":80"); then
        print_success "Porta 80 está livre"
        break
    fi
    echo -n "."
    sleep 2
done
echo ""
echo ""

# 7. Reiniciar frontend
print_info "7️⃣  Reiniciando frontend..."
docker-compose -f docker-compose.host-network.yml up -d frontend
sleep 5
print_success "Frontend reiniciado"
echo ""

# 8. Verificar se frontend está rodando
print_info "8️⃣  Verificando se frontend está rodando..."
FRONTEND_STATUS=$(docker inspect debrief-frontend --format='{{.State.Status}}' 2>/dev/null || echo "not_found")
if [ "$FRONTEND_STATUS" = "running" ]; then
    print_success "Frontend está rodando"
    
    # Verificar se porta 80 está em uso pelo frontend
    sleep 3
    FRONTEND_RESPONSE=$(curl -s -o /dev/null -w "%{http_code}" http://localhost:80/ 2>/dev/null || echo "000")
    if [ "$FRONTEND_RESPONSE" = "200" ]; then
        print_success "Frontend responde em localhost:80 (HTTP 200)"
    elif [ "$FRONTEND_RESPONSE" = "301" ] || [ "$FRONTEND_RESPONSE" = "302" ]; then
        print_warning "Frontend retorna redirecionamento (HTTP $FRONTEND_RESPONSE) - pode ser normal"
    else
        print_warning "Frontend retorna HTTP $FRONTEND_RESPONSE"
    fi
else
    print_error "Frontend não está rodando (status: $FRONTEND_STATUS)"
    print_info "Ver logs: docker-compose -f docker-compose.host-network.yml logs frontend"
fi
echo ""

# 9. Reiniciar backend (para aplicar correção do enum)
print_info "9️⃣  Reiniciando backend (para aplicar correção do enum)..."
docker-compose -f docker-compose.host-network.yml restart backend
sleep 5
print_success "Backend reiniciado"
echo ""

# 10. Testar login
print_info "🔟 Testando login..."
sleep 3
LOGIN_RESPONSE=$(curl -s -X POST http://localhost:2022/api/auth/login \
    -H "Content-Type: application/x-www-form-urlencoded" \
    -d "username=admin&password=admin123" 2>&1)

LOGIN_STATUS=$(echo "$LOGIN_RESPONSE" | grep -oP 'HTTP/\d\.\d \K\d+' || echo "000")
if [ "$LOGIN_STATUS" = "200" ]; then
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
fi
echo ""

# 11. Testar todas as conexões
print_info "1️⃣1️⃣  Testando todas as conexões..."
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

# 12. Resumo
echo "=========================================="
echo "📊 RESUMO"
echo "=========================================="
echo ""

if [ "$LOGIN_STATUS" = "200" ] && [ "$CADDY_API_RESPONSE" = "200" ] && [ "$FRONTEND_STATUS" = "running" ]; then
    print_success "✅ Todos os problemas corrigidos!"
    echo ""
    print_info "Acesse a aplicação:"
    echo "  🌐 http://82.25.92.217:2022/login"
    echo ""
    print_info "Credenciais:"
    echo "  Username: admin"
    echo "  Senha: admin123"
else
    print_warning "⚠️  Alguns problemas ainda persistem"
    echo ""
    if [ "$LOGIN_STATUS" != "200" ]; then
        print_info "Login:"
        echo "  - Execute: ./verificar-erro-500-login.sh"
    fi
    if [ "$FRONTEND_STATUS" != "running" ]; then
        print_info "Frontend:"
        echo "  - Ver logs: docker-compose -f docker-compose.host-network.yml logs frontend"
        echo "  - Verificar porta 80: netstat -tlnp | grep :80"
    fi
fi
echo ""

