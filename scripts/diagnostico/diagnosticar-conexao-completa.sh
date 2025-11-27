#!/bin/bash

# Script para Diagnosticar Conexão Completa
# Execute no servidor: ./diagnosticar-conexao-completa.sh

echo "=========================================="
echo "🔍 DIAGNÓSTICO COMPLETO DE CONEXÃO"
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

# 1. Verificar status de todos os containers
print_info "1️⃣  Verificando status de todos os containers..."
docker-compose -f docker-compose.host-network.yml ps
echo ""

# 2. Verificar backend
print_info "2️⃣  Verificando backend..."
if docker ps --filter "name=debrief-backend" --format "{{.Names}}" | grep -q debrief-backend; then
    BACKEND_NETWORK=$(docker inspect debrief-backend --format='{{.HostConfig.NetworkMode}}' 2>/dev/null)
    print_info "Network mode: $BACKEND_NETWORK"
    
    BACKEND_RESPONSE=$(curl -s -o /dev/null -w "%{http_code}" http://localhost:8000/health 2>/dev/null || echo "000")
    if [ "$BACKEND_RESPONSE" = "200" ]; then
        print_success "Backend responde em localhost:8000 (HTTP 200)"
        curl -s http://localhost:8000/health | head -3
    else
        print_error "Backend NÃO responde (HTTP $BACKEND_RESPONSE)"
    fi
    
    # Testar login endpoint
    LOGIN_RESPONSE=$(curl -s -o /dev/null -w "%{http_code}" -X POST http://localhost:8000/api/auth/login \
        -H "Content-Type: application/x-www-form-urlencoded" \
        -d "username=admin&password=admin123" 2>/dev/null || echo "000")
    if [ "$LOGIN_RESPONSE" = "200" ] || [ "$LOGIN_RESPONSE" = "401" ]; then
        print_success "Endpoint /api/auth/login responde (HTTP $LOGIN_RESPONSE)"
    else
        print_error "Endpoint /api/auth/login NÃO responde (HTTP $LOGIN_RESPONSE)"
    fi
else
    print_error "Backend não está rodando"
fi
echo ""

# 3. Verificar frontend
print_info "3️⃣  Verificando frontend..."
if docker ps --filter "name=debrief-frontend" --format "{{.Names}}" | grep -q debrief-frontend; then
    FRONTEND_NETWORK=$(docker inspect debrief-frontend --format='{{.HostConfig.NetworkMode}}' 2>/dev/null)
    print_info "Network mode: $FRONTEND_NETWORK"
    
    FRONTEND_RESPONSE=$(curl -s -o /dev/null -w "%{http_code}" http://localhost:80/ 2>/dev/null || echo "000")
    if [ "$FRONTEND_RESPONSE" = "200" ]; then
        print_success "Frontend responde em localhost:80 (HTTP 200)"
    else
        print_error "Frontend NÃO responde (HTTP $FRONTEND_RESPONSE)"
    fi
else
    print_error "Frontend não está rodando"
fi
echo ""

# 4. Verificar Caddy
print_info "4️⃣  Verificando Caddy..."
if docker ps --filter "name=debrief-caddy" --format "{{.Names}}" | grep -q debrief-caddy; then
    CADDY_NETWORK=$(docker inspect debrief-caddy --format='{{.HostConfig.NetworkMode}}' 2>/dev/null)
    print_info "Network mode: $CADDY_NETWORK"
    
    # Verificar se porta 2022 está em uso
    if netstat -tlnp 2>/dev/null | grep -q ":2022.*LISTEN" || ss -tlnp 2>/dev/null | grep -q ":2022"; then
        print_success "Porta 2022 está em uso"
    else
        print_error "Porta 2022 NÃO está em uso"
    fi
    
    # Testar via Caddy
    CADDY_API_RESPONSE=$(curl -s -o /dev/null -w "%{http_code}" http://localhost:2022/api/health 2>/dev/null || echo "000")
    if [ "$CADDY_API_RESPONSE" = "200" ]; then
        print_success "Caddy consegue fazer proxy para /api/health (HTTP 200)"
        curl -s http://localhost:2022/api/health | head -3
    else
        print_error "Caddy NÃO consegue fazer proxy (HTTP $CADDY_API_RESPONSE)"
    fi
    
    # Testar login via Caddy
    CADDY_LOGIN_RESPONSE=$(curl -s -o /dev/null -w "%{http_code}" -X POST http://localhost:2022/api/auth/login \
        -H "Content-Type: application/x-www-form-urlencoded" \
        -d "username=admin&password=admin123" 2>/dev/null || echo "000")
    if [ "$CADDY_LOGIN_RESPONSE" = "200" ] || [ "$CADDY_LOGIN_RESPONSE" = "401" ]; then
        print_success "Login via Caddy funciona (HTTP $CADDY_LOGIN_RESPONSE)"
    else
        print_error "Login via Caddy NÃO funciona (HTTP $CADDY_LOGIN_RESPONSE)"
    fi
    
    # Testar frontend via Caddy
    CADDY_FRONTEND_RESPONSE=$(curl -s -o /dev/null -w "%{http_code}" http://localhost:2022/ 2>/dev/null || echo "000")
    if [ "$CADDY_FRONTEND_RESPONSE" = "200" ]; then
        print_success "Frontend via Caddy funciona (HTTP 200)"
    else
        print_error "Frontend via Caddy NÃO funciona (HTTP $CADDY_FRONTEND_RESPONSE)"
    fi
else
    print_error "Caddy não está rodando"
fi
echo ""

# 5. Verificar Caddyfile
print_info "5️⃣  Verificando Caddyfile..."
if [ -f "./Caddyfile" ]; then
    print_success "Caddyfile encontrado"
    echo ""
    print_info "Configuração:"
    cat Caddyfile
    echo ""
else
    print_error "Caddyfile não encontrado"
fi
echo ""

# 6. Verificar logs do backend
print_info "6️⃣  Verificando logs do backend (últimas 10 linhas com erros)..."
echo "----------------------------------------"
docker-compose -f docker-compose.host-network.yml logs --tail=30 backend 2>&1 | grep -i "error\|exception\|traceback\|failed" | tail -10 || echo "Nenhum erro encontrado"
echo ""

# 7. Verificar logs do Caddy
print_info "7️⃣  Verificando logs do Caddy (últimas 10 linhas com erros)..."
echo "----------------------------------------"
docker-compose -f docker-compose.host-network.yml logs --tail=30 caddy 2>&1 | grep -i "error\|404\|502\|failed" | tail -10 || echo "Nenhum erro encontrado"
echo ""

# 8. Verificar se usuário admin existe
print_info "8️⃣  Verificando se usuário admin existe no banco..."
export PGPASSWORD="<redacted-db-password>"
USER_EXISTS=$(psql -h localhost -p 5432 -U postgres -d dbrief -tAc "SELECT COUNT(*) FROM users WHERE username = 'admin' OR email = 'admin@debrief.com';" 2>/dev/null || echo "0")
unset PGPASSWORD

if [ "$USER_EXISTS" -gt 0 ]; then
    print_success "Usuário admin existe no banco"
else
    print_error "Usuário admin NÃO existe no banco"
    print_info "Execute: ./criar-usuario-admin.sh"
fi
echo ""

# 9. Testar conexão externa
print_info "9️⃣  Testando conexão externa (82.25.92.217:2022)..."
EXTERNAL_RESPONSE=$(curl -s -o /dev/null -w "%{http_code}" http://82.25.92.217:2022/api/health 2>/dev/null || echo "000")
if [ "$EXTERNAL_RESPONSE" = "200" ]; then
    print_success "Conexão externa funciona (HTTP 200)"
elif [ "$EXTERNAL_RESPONSE" = "000" ]; then
    print_warning "Não foi possível testar conexão externa (pode ser firewall)"
else
    print_warning "Conexão externa retorna HTTP $EXTERNAL_RESPONSE"
fi
echo ""

# 10. Resumo e recomendações
echo "=========================================="
echo "📊 RESUMO E RECOMENDAÇÕES"
echo "=========================================="
echo ""

ISSUES=0

if [ "$BACKEND_RESPONSE" != "200" ]; then
    print_error "Backend não está respondendo"
    ISSUES=$((ISSUES + 1))
fi

if [ "$FRONTEND_RESPONSE" != "200" ]; then
    print_error "Frontend não está respondendo"
    ISSUES=$((ISSUES + 1))
fi

if [ "$CADDY_API_RESPONSE" != "200" ]; then
    print_error "Caddy não consegue fazer proxy"
    ISSUES=$((ISSUES + 1))
fi

if [ "$CADDY_NETWORK" != "host" ]; then
    print_error "Caddy não está em network_mode: host"
    ISSUES=$((ISSUES + 1))
fi

if [ "$FRONTEND_NETWORK" != "host" ]; then
    print_error "Frontend não está em network_mode: host"
    ISSUES=$((ISSUES + 1))
fi

if [ "$USER_EXISTS" -eq 0 ]; then
    print_error "Usuário admin não existe"
    ISSUES=$((ISSUES + 1))
fi

if [ $ISSUES -eq 0 ]; then
    print_success "✅ Tudo parece estar funcionando!"
    echo ""
    print_info "Se ainda há erro, pode ser:"
    echo "  - Cache do navegador (limpe com Ctrl+Shift+Delete)"
    echo "  - Firewall bloqueando conexão externa"
    echo "  - Problema de CORS"
else
    print_error "❌ Encontrados $ISSUES problema(s)"
    echo ""
    print_info "Soluções:"
    echo ""
    
    if [ "$BACKEND_RESPONSE" != "200" ]; then
        echo "  1. Reiniciar backend:"
        echo "     docker-compose -f docker-compose.host-network.yml restart backend"
    fi
    
    if [ "$FRONTEND_RESPONSE" != "200" ]; then
        echo "  2. Reiniciar frontend:"
        echo "     docker-compose -f docker-compose.host-network.yml restart frontend"
    fi
    
    if [ "$CADDY_NETWORK" != "host" ] || [ "$FRONTEND_NETWORK" != "host" ]; then
        echo "  3. Aplicar correção de rede:"
        echo "     ./aplicar-correcao-404.sh"
    fi
    
    if [ "$USER_EXISTS" -eq 0 ]; then
        echo "  4. Criar usuário admin:"
        echo "     ./criar-usuario-admin.sh"
    fi
    
    if [ "$CADDY_API_RESPONSE" != "200" ]; then
        echo "  5. Verificar logs do Caddy:"
        echo "     docker-compose -f docker-compose.host-network.yml logs caddy | tail -50"
    fi
fi
echo ""

