#!/bin/bash

# Script para Aplicar Todas as Correções Finais
# Execute no servidor: ./aplicar-correcoes-finais.sh

echo "=========================================="
echo "🔧 APLICAR CORREÇÕES FINAIS"
echo "=========================================="
echo ""

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

# 1. Fazer pull
print_info "1️⃣  Fazendo pull das atualizações..."
git pull
echo ""

# 2. Rebuild do backend (para incluir /api/health)
print_info "2️⃣  Fazendo rebuild do backend (para incluir /api/health)..."
docker-compose -f docker-compose.host-network.yml build --no-cache backend
print_success "Backend rebuild concluído"
echo ""

# 3. Reiniciar backend
print_info "3️⃣  Reiniciando backend..."
docker-compose -f docker-compose.host-network.yml stop backend
docker-compose -f docker-compose.host-network.yml rm -f backend
docker-compose -f docker-compose.host-network.yml up -d backend
sleep 10
print_success "Backend reiniciado"
echo ""

# 4. Verificar se backend está healthy
print_info "4️⃣  Verificando se backend está healthy..."
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

# 5. Testar /api/health no backend
print_info "5️⃣  Testando /api/health no backend..."
BACKEND_API_HEALTH=$(curl -s -o /dev/null -w "%{http_code}" http://localhost:8000/api/health 2>/dev/null || echo "000")
if [ "$BACKEND_API_HEALTH" = "200" ]; then
    print_success "Backend /api/health funciona (HTTP 200)"
    curl -s http://localhost:8000/api/health | head -3
else
    print_info "Backend /api/health retorna HTTP $BACKEND_API_HEALTH (pode ser normal se ainda não foi atualizado)"
fi
echo ""

# 6. Reiniciar Caddy
print_info "6️⃣  Reiniciando Caddy (para aplicar novo Caddyfile)..."
docker-compose -f docker-compose.host-network.yml restart caddy
sleep 3
print_success "Caddy reiniciado"
echo ""

# 7. Testar conexões
print_info "7️⃣  Testando conexões..."
sleep 3

# Backend direto
BACKEND_RESPONSE=$(curl -s -o /dev/null -w "%{http_code}" http://localhost:8000/health 2>/dev/null || echo "000")
if [ "$BACKEND_RESPONSE" = "200" ]; then
    print_success "Backend responde (HTTP 200)"
else
    print_info "Backend retorna HTTP $BACKEND_RESPONSE"
fi

# Caddy API
CADDY_API_RESPONSE=$(curl -s -o /dev/null -w "%{http_code}" http://localhost:2022/api/health 2>/dev/null || echo "000")
if [ "$CADDY_API_RESPONSE" = "200" ]; then
    print_success "Caddy API funciona (HTTP 200)"
    curl -s http://localhost:2022/api/health | head -3
else
    print_info "Caddy API retorna HTTP $CADDY_API_RESPONSE"
fi

# Caddy Frontend
CADDY_FRONTEND_RESPONSE=$(curl -s -o /dev/null -w "%{http_code}" http://localhost:2022/ 2>/dev/null || echo "000")
if [ "$CADDY_FRONTEND_RESPONSE" = "200" ]; then
    print_success "Caddy Frontend funciona (HTTP 200)"
else
    print_info "Caddy Frontend retorna HTTP $CADDY_FRONTEND_RESPONSE"
fi

# Login via Caddy
CADDY_LOGIN_RESPONSE=$(curl -s -o /dev/null -w "%{http_code}" -X POST http://localhost:2022/api/auth/login \
    -H "Content-Type: application/x-www-form-urlencoded" \
    -d "username=admin&password=admin123" 2>/dev/null || echo "000")
if [ "$CADDY_LOGIN_RESPONSE" = "200" ]; then
    print_success "Login via Caddy funciona (HTTP 200)"
elif [ "$CADDY_LOGIN_RESPONSE" = "401" ]; then
    print_info "Login retorna 401 (credenciais inválidas - mas endpoint funciona)"
elif [ "$CADDY_LOGIN_RESPONSE" = "500" ]; then
    print_info "Login retorna 500 (erro no servidor)"
    print_info "Execute: ./verificar-erro-500-login.sh"
else
    print_info "Login retorna HTTP $CADDY_LOGIN_RESPONSE"
fi
echo ""

# 8. Resumo
echo "=========================================="
if [ "$CADDY_API_RESPONSE" = "200" ] && [ "$CADDY_FRONTEND_RESPONSE" = "200" ]; then
    print_success "✅ Correções aplicadas com sucesso!"
    echo ""
    print_info "Acesse a aplicação:"
    echo "  🌐 http://82.25.92.217:2022/login"
    echo ""
    if [ "$CADDY_LOGIN_RESPONSE" = "500" ]; then
        print_info "⚠️  Se login ainda retornar erro 500, execute:"
        echo "  ./verificar-erro-500-login.sh"
    fi
else
    print_info "⚠️  Alguns problemas ainda persistem"
    echo ""
    print_info "Execute diagnóstico:"
    echo "  ./diagnosticar-conexao-completa.sh"
fi
echo ""

