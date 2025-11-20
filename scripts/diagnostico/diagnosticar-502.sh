#!/bin/bash

# Script para Diagnosticar Erro 502 (Bad Gateway)
# Execute no servidor: ./diagnosticar-502.sh

echo "=========================================="
echo "🔍 DIAGNÓSTICO ERRO 502 (BAD GATEWAY)"
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

# 1. Verificar status dos containers
print_info "1️⃣  Verificando status dos containers..."
docker-compose -f docker-compose.host-network.yml ps
echo ""

# 2. Verificar se backend está rodando
print_info "2️⃣  Verificando se backend está rodando..."
if docker ps --filter "name=debrief-backend" --format "{{.Names}}" | grep -q debrief-backend; then
    BACKEND_STATUS=$(docker inspect debrief-backend --format='{{.State.Status}}' 2>/dev/null)
    print_info "Backend status: $BACKEND_STATUS"
    
    if [ "$BACKEND_STATUS" = "running" ]; then
        print_success "Backend está rodando"
    else
        print_error "Backend não está rodando (status: $BACKEND_STATUS)"
        print_info "Ver logs: docker-compose -f docker-compose.host-network.yml logs backend"
    fi
else
    print_error "Container backend não encontrado"
fi
echo ""

# 3. Verificar health check do backend
print_info "3️⃣  Verificando health check do backend..."
HEALTH_STATUS=$(docker inspect debrief-backend --format='{{.State.Health.Status}}' 2>/dev/null || echo "no_healthcheck")
if [ "$HEALTH_STATUS" = "healthy" ]; then
    print_success "Backend está healthy"
elif [ "$HEALTH_STATUS" = "starting" ]; then
    print_warning "Backend ainda está iniciando..."
elif [ "$HEALTH_STATUS" = "unhealthy" ]; then
    print_error "Backend está unhealthy"
    print_info "Últimas tentativas de health check:"
    docker inspect debrief-backend --format='{{range .State.Health.Log}}{{.Output}}{{end}}' 2>/dev/null | tail -3
else
    print_warning "Health status: $HEALTH_STATUS"
fi
echo ""

# 4. Testar endpoint de health diretamente
print_info "4️⃣  Testando endpoint /health diretamente no backend..."
HEALTH_RESPONSE=$(curl -s -o /dev/null -w "%{http_code}" http://localhost:2025/health 2>/dev/null || echo "000")
if [ "$HEALTH_RESPONSE" = "200" ]; then
    print_success "Backend responde em http://localhost:2025/health"
    curl -s http://localhost:2025/health | head -3
elif [ "$HEALTH_RESPONSE" = "000" ]; then
    print_error "Backend não responde (não conseguiu conectar)"
else
    print_warning "Backend retornou HTTP $HEALTH_RESPONSE"
fi
echo ""

# 5. Testar endpoint /api/auth/login
print_info "5️⃣  Testando endpoint /api/auth/login..."
LOGIN_RESPONSE=$(curl -s -o /dev/null -w "%{http_code}" -X POST http://localhost:2025/api/auth/login \
    -H "Content-Type: application/x-www-form-urlencoded" \
    -d "username=admin&password=admin123" 2>/dev/null || echo "000")
if [ "$LOGIN_RESPONSE" = "200" ] || [ "$LOGIN_RESPONSE" = "401" ]; then
    print_success "Backend responde em /api/auth/login (HTTP $LOGIN_RESPONSE)"
    if [ "$LOGIN_RESPONSE" = "401" ]; then
        print_warning "401 = Credenciais inválidas (mas backend está funcionando)"
    fi
else
    print_error "Backend não responde em /api/auth/login (HTTP $LOGIN_RESPONSE)"
fi
echo ""

# 6. Verificar se Caddy está rodando
print_info "6️⃣  Verificando se Caddy está rodando..."
if docker ps --filter "name=debrief-caddy" --format "{{.Names}}" | grep -q debrief-caddy; then
    print_success "Caddy está rodando"
    
    # Testar proxy do Caddy
    print_info "Testando proxy do Caddy para /api..."
    CADDY_API_RESPONSE=$(curl -s -o /dev/null -w "%{http_code}" http://localhost:2022/api/health 2>/dev/null || echo "000")
    if [ "$CADDY_API_RESPONSE" = "200" ]; then
        print_success "Caddy consegue fazer proxy para /api (HTTP 200)"
    else
        print_error "Caddy não consegue fazer proxy para /api (HTTP $CADDY_API_RESPONSE)"
    fi
else
    print_error "Caddy não está rodando"
fi
echo ""

# 7. Verificar logs do backend
print_info "7️⃣  Verificando logs do backend (últimas 20 linhas)..."
echo "----------------------------------------"
docker-compose -f docker-compose.host-network.yml logs --tail=20 backend 2>&1 | grep -v "^$"
echo ""

# 8. Verificar logs do Caddy
print_info "8️⃣  Verificando logs do Caddy (últimas 10 linhas)..."
echo "----------------------------------------"
docker-compose -f docker-compose.host-network.yml logs --tail=10 caddy 2>&1 | grep -v "^$"
echo ""

# 9. Verificar Caddyfile
print_info "9️⃣  Verificando configuração do Caddyfile..."
if [ -f "./Caddyfile" ]; then
    print_success "Caddyfile encontrado"
    echo "Conteúdo do Caddyfile:"
    cat Caddyfile | head -30
else
    print_error "Caddyfile não encontrado"
fi
echo ""

# 10. Testar conexão do frontend com backend via Caddy
print_info "🔟 Testando conexão frontend -> Caddy -> Backend..."
FRONTEND_TEST=$(curl -s -o /dev/null -w "%{http_code}" http://82.25.92.217:2022/api/health 2>/dev/null || echo "000")
if [ "$FRONTEND_TEST" = "200" ]; then
    print_success "Frontend consegue acessar backend via Caddy (HTTP 200)"
elif [ "$FRONTEND_TEST" = "502" ]; then
    print_error "Erro 502: Caddy não consegue fazer proxy para backend"
    print_info "Possíveis causas:"
    echo "  - Backend não está rodando"
    echo "  - Backend não está healthy"
    echo "  - Caddyfile configurado incorretamente"
    echo "  - Backend não está acessível na rede"
else
    print_warning "Resposta HTTP $FRONTEND_TEST"
fi
echo ""

# 11. Resumo e recomendações
echo "=========================================="
echo "📊 RESUMO E RECOMENDAÇÕES"
echo "=========================================="
echo ""

if [ "$HEALTH_RESPONSE" != "200" ]; then
    print_error "Backend não está respondendo corretamente"
    echo ""
    print_info "Soluções:"
    echo "  1. Verificar logs: docker-compose -f docker-compose.host-network.yml logs backend"
    echo "  2. Reiniciar backend: docker-compose -f docker-compose.host-network.yml restart backend"
    echo "  3. Verificar se banco está acessível: ./testar-usuario-postgres.sh"
    echo "  4. Rebuild se necessário: docker-compose -f docker-compose.host-network.yml build --no-cache backend"
elif [ "$FRONTEND_TEST" = "502" ]; then
    print_error "Caddy não consegue fazer proxy para backend"
    echo ""
    print_info "Soluções:"
    echo "  1. Verificar se backend está healthy: docker-compose -f docker-compose.host-network.yml ps backend"
    echo "  2. Reiniciar Caddy: docker-compose -f docker-compose.host-network.yml restart caddy"
    echo "  3. Verificar Caddyfile: cat Caddyfile"
    echo "  4. Verificar logs do Caddy: docker-compose -f docker-compose.host-network.yml logs caddy"
else
    print_success "Tudo parece estar funcionando!"
    echo ""
    print_info "Se ainda há erro 502, pode ser cache do navegador."
    echo "Tente:"
    echo "  - Limpar cache do navegador (Ctrl+Shift+Delete)"
    echo "  - Fazer hard refresh (Ctrl+F5)"
    echo "  - Testar em modo anônimo"
fi
echo ""

