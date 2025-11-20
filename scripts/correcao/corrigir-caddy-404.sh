#!/bin/bash

# Script para Corrigir Erro 404 do Caddy na API
# Execute no servidor: ./corrigir-caddy-404.sh

echo "=========================================="
echo "🔧 CORRIGIR ERRO 404 DO CADDY NA API"
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

# 1. Verificar se backend está acessível
print_info "1️⃣  Verificando se backend está acessível..."
BACKEND_RESPONSE=$(curl -s -o /dev/null -w "%{http_code}" http://localhost:8000/health 2>/dev/null || echo "000")
if [ "$BACKEND_RESPONSE" = "200" ]; then
    print_success "Backend responde em localhost:8000 (HTTP 200)"
    curl -s http://localhost:8000/health | head -3
else
    print_error "Backend NÃO responde (HTTP $BACKEND_RESPONSE)"
    exit 1
fi
echo ""

# 2. Testar endpoint /api/health diretamente no backend
print_info "2️⃣  Testando /api/health diretamente no backend..."
BACKEND_API_RESPONSE=$(curl -s -o /dev/null -w "%{http_code}" http://localhost:8000/api/health 2>/dev/null || echo "000")
if [ "$BACKEND_API_RESPONSE" = "200" ]; then
    print_success "Backend /api/health responde (HTTP 200)"
    curl -s http://localhost:8000/api/health | head -3
else
    print_warning "Backend /api/health retorna HTTP $BACKEND_API_RESPONSE"
    print_info "Testando /health (sem /api)..."
    BACKEND_HEALTH_RESPONSE=$(curl -s -o /dev/null -w "%{http_code}" http://localhost:8000/health 2>/dev/null || echo "000")
    if [ "$BACKEND_HEALTH_RESPONSE" = "200" ]; then
        print_success "Backend /health responde (HTTP 200)"
        print_info "O backend não tem /api/health, apenas /health"
    fi
fi
echo ""

# 3. Verificar Caddyfile
print_info "3️⃣  Verificando Caddyfile..."
if [ -f "./Caddyfile" ]; then
    print_success "Caddyfile encontrado"
    echo ""
    print_info "Configuração atual:"
    cat Caddyfile
    echo ""
    
    # Verificar se a rota /api está configurada corretamente
    if grep -q "path /api" Caddyfile; then
        print_success "Rota /api está configurada"
    else
        print_error "Rota /api NÃO está configurada"
    fi
else
    print_error "Caddyfile não encontrado"
    exit 1
fi
echo ""

# 4. Testar Caddy diretamente
print_info "4️⃣  Testando Caddy diretamente..."
CADDY_API_RESPONSE=$(curl -s -o /dev/null -w "%{http_code}" http://localhost:2022/api/health 2>/dev/null || echo "000")
if [ "$CADDY_API_RESPONSE" = "200" ]; then
    print_success "Caddy /api/health funciona (HTTP 200)"
    curl -s http://localhost:2022/api/health | head -3
elif [ "$CADDY_API_RESPONSE" = "404" ]; then
    print_error "Caddy retorna 404 para /api/health"
    print_info "Testando /health (sem /api)..."
    CADDY_HEALTH_RESPONSE=$(curl -s -o /dev/null -w "%{http_code}" http://localhost:2022/health 2>/dev/null || echo "000")
    if [ "$CADDY_HEALTH_RESPONSE" = "200" ]; then
        print_success "Caddy /health funciona (HTTP 200)"
        print_info "O problema pode ser que o backend não tem /api/health, apenas /health"
    fi
else
    print_warning "Caddy retorna HTTP $CADDY_API_RESPONSE"
fi
echo ""

# 5. Verificar logs do Caddy
print_info "5️⃣  Verificando logs do Caddy (últimas 20 linhas)..."
echo "----------------------------------------"
docker-compose -f docker-compose.host-network.yml logs --tail=20 caddy 2>&1 | grep -E "GET|POST|error|404|502" | tail -10 || echo "Nenhum erro encontrado"
echo ""

# 6. Verificar se o problema é que o backend não tem /api/health
print_info "6️⃣  Verificando rotas disponíveis no backend..."
BACKEND_ROUTES=$(curl -s http://localhost:8000/api/docs 2>/dev/null | grep -oP 'href="[^"]*"' | head -10 || echo "")
if [ -n "$BACKEND_ROUTES" ]; then
    print_info "Backend tem documentação em /api/docs"
    print_info "Testando acesso via Caddy..."
    CADDY_DOCS_RESPONSE=$(curl -s -o /dev/null -w "%{http_code}" http://localhost:2022/api/docs 2>/dev/null || echo "000")
    if [ "$CADDY_DOCS_RESPONSE" = "200" ]; then
        print_success "Caddy consegue acessar /api/docs (HTTP 200)"
    else
        print_warning "Caddy retorna HTTP $CADDY_DOCS_RESPONSE para /api/docs"
    fi
fi
echo ""

# 7. Testar login endpoint
print_info "7️⃣  Testando endpoint de login via Caddy..."
CADDY_LOGIN_RESPONSE=$(curl -s -X POST http://localhost:2022/api/auth/login \
    -H "Content-Type: application/x-www-form-urlencoded" \
    -d "username=admin&password=admin123" 2>&1)

CADDY_LOGIN_STATUS=$(echo "$CADDY_LOGIN_RESPONSE" | grep -oP 'HTTP/\d\.\d \K\d+' || echo "000")
if [ "$CADDY_LOGIN_STATUS" = "200" ]; then
    print_success "Login via Caddy funciona (HTTP 200)"
    echo "$CADDY_LOGIN_RESPONSE" | tail -3
elif [ "$CADDY_LOGIN_STATUS" = "404" ]; then
    print_error "Login via Caddy retorna 404"
    print_info "Caddy não está conseguindo fazer proxy para /api/auth/login"
elif [ "$CADDY_LOGIN_STATUS" = "500" ]; then
    print_error "Login via Caddy retorna 500"
    print_info "Execute: ./verificar-erro-500-login.sh"
else
    print_warning "Login via Caddy retorna HTTP $CADDY_LOGIN_STATUS"
fi
echo ""

# 8. Verificar se o problema é a ordem das rotas no Caddyfile
print_info "8️⃣  Verificando ordem das rotas no Caddyfile..."
# A rota mais específica (/api/*) deve vir antes da rota genérica (handle)
API_BEFORE_HANDLE=$(grep -n "path /api" Caddyfile | head -1 | cut -d: -f1)
HANDLE_BEFORE_API=$(grep -n "^    handle {" Caddyfile | head -1 | cut -d: -f1)

if [ -n "$API_BEFORE_HANDLE" ] && [ -n "$HANDLE_BEFORE_API" ]; then
    if [ "$API_BEFORE_HANDLE" -lt "$HANDLE_BEFORE_API" ]; then
        print_success "Ordem das rotas está correta (/api antes de handle)"
    else
        print_error "Ordem das rotas está INCORRETA (handle antes de /api)"
        print_info "Corrigindo Caddyfile..."
        # Fazer backup
        cp Caddyfile Caddyfile.backup.$(date +%Y%m%d_%H%M%S)
        # Reordenar (isso é complexo, melhor fazer manualmente ou recriar)
        print_warning "Reordenação manual necessária"
    fi
fi
echo ""

# 9. Resumo e correção
echo "=========================================="
echo "📊 RESUMO E CORREÇÃO"
echo "=========================================="
echo ""

if [ "$CADDY_API_RESPONSE" = "404" ] && [ "$BACKEND_HEALTH_RESPONSE" = "200" ]; then
    print_info "Problema identificado: Backend não tem /api/health, apenas /health"
    print_info "O Caddyfile está configurado para /api/*, mas o backend pode não ter prefixo /api"
    echo ""
    print_info "Soluções:"
    echo "  1. Verificar se o backend tem rotas em /api/*"
    echo "  2. Testar: curl http://localhost:8000/api/docs"
    echo "  3. Se não funcionar, o backend pode não ter prefixo /api"
elif [ "$CADDY_LOGIN_STATUS" = "404" ]; then
    print_error "Caddy não consegue fazer proxy para /api/auth/login"
    echo ""
    print_info "Soluções:"
    echo "  1. Verificar logs do Caddy: docker-compose -f docker-compose.host-network.yml logs caddy | tail -50"
    echo "  2. Verificar se backend está em localhost:8000: curl http://localhost:8000/health"
    echo "  3. Reiniciar Caddy: docker-compose -f docker-compose.host-network.yml restart caddy"
    echo "  4. Verificar Caddyfile: cat Caddyfile"
else
    print_success "Tudo parece estar funcionando!"
    echo ""
    print_info "Acesse a aplicação:"
    echo "  🌐 http://82.25.92.217:2022/login"
fi
echo ""

