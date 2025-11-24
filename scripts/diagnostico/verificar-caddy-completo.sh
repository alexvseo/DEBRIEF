#!/bin/bash

# Script para Verificação Completa do Caddy
# Execute no servidor: ./verificar-caddy-completo.sh

echo "=========================================="
echo "🔍 VERIFICAÇÃO COMPLETA DO CADDY"
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

# 2. Verificar se Caddy está em network_mode: host
print_info "2️⃣  Verificando configuração do Caddy..."
CADDY_NETWORK=$(docker inspect debrief-caddy --format='{{.HostConfig.NetworkMode}}' 2>/dev/null)
if [ "$CADDY_NETWORK" = "host" ]; then
    print_success "Caddy está em network_mode: host"
else
    print_error "Caddy NÃO está em network_mode: host (atual: $CADDY_NETWORK)"
    print_info "Execute: docker-compose -f docker-compose.host-network.yml up -d caddy"
fi
echo ""

# 3. Verificar se Caddy está escutando na porta 2022
print_info "3️⃣  Verificando se Caddy está escutando na porta 2022..."
if netstat -tlnp 2>/dev/null | grep -q ":2022.*LISTEN" || ss -tlnp 2>/dev/null | grep -q ":2022"; then
    print_success "Porta 2022 está em uso (provavelmente pelo Caddy)"
    netstat -tlnp 2>/dev/null | grep ":2022" || ss -tlnp 2>/dev/null | grep ":2022"
else
    print_error "Porta 2022 NÃO está em uso"
    print_info "Caddy pode não estar rodando ou não está escutando na porta correta"
fi
echo ""

# 4. Verificar se backend está acessível em localhost:8000
print_info "4️⃣  Verificando se backend está acessível em localhost:8000..."
BACKEND_RESPONSE=$(curl -s -o /dev/null -w "%{http_code}" http://localhost:8000/health 2>/dev/null || echo "000")
if [ "$BACKEND_RESPONSE" = "200" ]; then
    print_success "Backend responde em localhost:8000 (HTTP 200)"
    curl -s http://localhost:8000/health | head -3
else
    print_error "Backend NÃO responde em localhost:8000 (HTTP $BACKEND_RESPONSE)"
    print_info "Verifique se backend está rodando: docker-compose -f docker-compose.host-network.yml ps backend"
fi
echo ""

# 5. Verificar se frontend está acessível
print_info "5️⃣  Verificando se frontend está acessível..."
FRONTEND_IP=$(docker inspect debrief-frontend --format='{{range .NetworkSettings.Networks}}{{.IPAddress}}{{end}}' 2>/dev/null)
if [ -n "$FRONTEND_IP" ]; then
    print_info "IP do frontend: $FRONTEND_IP"
    FRONTEND_RESPONSE=$(curl -s -o /dev/null -w "%{http_code}" http://$FRONTEND_IP:80/ 2>/dev/null || echo "000")
    if [ "$FRONTEND_RESPONSE" = "200" ]; then
        print_success "Frontend responde em $FRONTEND_IP:80 (HTTP 200)"
    else
        print_error "Frontend NÃO responde em $FRONTEND_IP:80 (HTTP $FRONTEND_RESPONSE)"
    fi
else
    print_error "Não foi possível descobrir IP do frontend"
fi
echo ""

# 6. Verificar Caddyfile
print_info "6️⃣  Verificando configuração do Caddyfile..."
if [ -f "./Caddyfile" ]; then
    print_success "Caddyfile encontrado"
    echo ""
    print_info "Porta configurada:"
    grep "^:2022\|^:80" Caddyfile | head -1
    echo ""
    print_info "Backend configurado:"
    grep "reverse_proxy.*localhost:8000" Caddyfile | head -1
    echo ""
    print_info "Frontend configurado:"
    grep "reverse_proxy.*172.19.0" Caddyfile | head -1
else
    print_error "Caddyfile não encontrado"
fi
echo ""

# 7. Testar acesso via Caddy
print_info "7️⃣  Testando acesso via Caddy (porta 2022)..."
CADDY_API_RESPONSE=$(curl -s -o /dev/null -w "%{http_code}" http://localhost:2022/api/health 2>/dev/null || echo "000")
if [ "$CADDY_API_RESPONSE" = "200" ]; then
    print_success "✅ Caddy consegue fazer proxy para /api (HTTP 200)"
    curl -s http://localhost:2022/api/health | head -3
elif [ "$CADDY_API_RESPONSE" = "502" ]; then
    print_error "❌ Erro 502: Caddy não consegue fazer proxy para backend"
elif [ "$CADDY_API_RESPONSE" = "000" ]; then
    print_error "❌ Não conseguiu conectar ao Caddy na porta 2022"
else
    print_warning "Resposta HTTP $CADDY_API_RESPONSE"
fi
echo ""

# 8. Verificar logs do Caddy
print_info "8️⃣  Verificando logs do Caddy (últimas 15 linhas)..."
echo "----------------------------------------"
docker-compose -f docker-compose.host-network.yml logs --tail=15 caddy 2>&1 | grep -v "^$"
echo ""

# 9. Verificar se Caddy está rodando
print_info "9️⃣  Verificando se processo Caddy está rodando..."
if docker ps --filter "name=debrief-caddy" --format "{{.Names}}" | grep -q debrief-caddy; then
    CADDY_STATUS=$(docker inspect debrief-caddy --format='{{.State.Status}}' 2>/dev/null)
    print_info "Status do container: $CADDY_STATUS"
    if [ "$CADDY_STATUS" = "running" ]; then
        print_success "Container Caddy está rodando"
    else
        print_error "Container Caddy não está rodando (status: $CADDY_STATUS)"
    fi
else
    print_error "Container Caddy não encontrado"
fi
echo ""

# 10. Resumo e recomendações
echo "=========================================="
echo "📊 RESUMO E RECOMENDAÇÕES"
echo "=========================================="
echo ""

if [ "$CADDY_API_RESPONSE" = "200" ]; then
    print_success "✅ Tudo está funcionando!"
    echo ""
    print_info "Acesse a aplicação:"
    echo "  🌐 http://82.25.92.217:2022/login"
elif [ "$BACKEND_RESPONSE" != "200" ]; then
    print_error "Backend não está acessível"
    echo ""
    print_info "Soluções:"
    echo "  1. Verificar se backend está rodando: docker-compose -f docker-compose.host-network.yml ps backend"
    echo "  2. Reiniciar backend: docker-compose -f docker-compose.host-network.yml restart backend"
    echo "  3. Ver logs: docker-compose -f docker-compose.host-network.yml logs backend"
elif [ "$CADDY_NETWORK" != "host" ]; then
    print_error "Caddy não está em network_mode: host"
    echo ""
    print_info "Solução:"
    echo "  1. Parar Caddy: docker-compose -f docker-compose.host-network.yml stop caddy"
    echo "  2. Reiniciar com nova configuração: docker-compose -f docker-compose.host-network.yml up -d caddy"
elif [ "$CADDY_API_RESPONSE" = "502" ]; then
    print_error "Caddy não consegue fazer proxy para backend"
    echo ""
    print_info "Soluções:"
    echo "  1. Verificar logs: docker-compose -f docker-compose.host-network.yml logs caddy | tail -30"
    echo "  2. Verificar se backend está em localhost:8000: curl http://localhost:8000/health"
    echo "  3. Reiniciar Caddy: docker-compose -f docker-compose.host-network.yml restart caddy"
else
    print_warning "Verifique os logs acima para identificar o problema"
fi
echo ""

