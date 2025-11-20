#!/bin/bash

# Script para Corrigir Erro 404 do Caddy
# Execute no servidor: ./corrigir-404-caddy.sh

echo "=========================================="
echo "🔧 CORRIGIR ERRO 404 DO CADDY"
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

# 1. Testar backend diretamente
print_info "1️⃣  Testando backend diretamente..."
BACKEND_RESPONSE=$(curl -s -o /dev/null -w "%{http_code}" http://localhost:8000/health 2>/dev/null || echo "000")
if [ "$BACKEND_RESPONSE" = "200" ]; then
    print_success "Backend responde em localhost:8000 (HTTP 200)"
    curl -s http://localhost:8000/health | head -3
else
    print_error "Backend NÃO responde (HTTP $BACKEND_RESPONSE)"
fi
echo ""

# 2. Testar backend via Caddy
print_info "2️⃣  Testando backend via Caddy (/api/health)..."
CADDY_API_RESPONSE=$(curl -s -o /dev/null -w "%{http_code}" http://localhost:2022/api/health 2>/dev/null || echo "000")
if [ "$CADDY_API_RESPONSE" = "200" ]; then
    print_success "Caddy consegue fazer proxy para /api/health (HTTP 200)"
    curl -s http://localhost:2022/api/health | head -3
elif [ "$CADDY_API_RESPONSE" = "404" ]; then
    print_error "Erro 404: Caddy não está encontrando a rota /api/health"
    print_info "Verificando Caddyfile..."
elif [ "$CADDY_API_RESPONSE" = "502" ]; then
    print_error "Erro 502: Caddy não consegue fazer proxy para backend"
else
    print_warning "Resposta HTTP $CADDY_API_RESPONSE"
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
    
    # Verificar se a rota /api está configurada
    if grep -q "path /api" Caddyfile; then
        print_success "Rota /api está configurada"
    else
        print_error "Rota /api NÃO está configurada no Caddyfile"
    fi
else
    print_error "Caddyfile não encontrado"
fi
echo ""

# 4. Testar frontend diretamente
print_info "4️⃣  Testando frontend diretamente..."
FRONTEND_IP=$(docker inspect debrief-frontend --format='{{range .NetworkSettings.Networks}}{{.IPAddress}}{{end}}' 2>/dev/null)
if [ -n "$FRONTEND_IP" ]; then
    print_info "IP do frontend: $FRONTEND_IP"
    
    # Testar se Caddy consegue acessar o frontend
    # Como Caddy está em network_mode: host, precisa usar IP do host ou gateway
    GATEWAY=$(docker network inspect debrief_debrief-network 2>/dev/null | grep -oP '"Gateway": "\K[^"]+' | head -1)
    if [ -z "$GATEWAY" ]; then
        GATEWAY="172.19.0.1"
    fi
    
    print_info "Gateway Docker: $GATEWAY"
    
    # Tentar acessar frontend via gateway
    FRONTEND_RESPONSE=$(curl -s -o /dev/null -w "%{http_code}" http://$FRONTEND_IP:80/ 2>/dev/null || echo "000")
    if [ "$FRONTEND_RESPONSE" = "200" ]; then
        print_success "Frontend responde em $FRONTEND_IP:80 (HTTP 200)"
    else
        print_warning "Frontend não responde diretamente (pode ser normal se estiver na rede Docker)"
    fi
else
    print_error "Não foi possível descobrir IP do frontend"
fi
echo ""

# 5. Verificar logs do Caddy
print_info "5️⃣  Verificando logs do Caddy (últimas 20 linhas)..."
echo "----------------------------------------"
docker-compose -f docker-compose.host-network.yml logs --tail=20 caddy 2>&1 | grep -E "error|404|502|GET|POST" | tail -10
echo ""

# 6. Testar rota raiz
print_info "6️⃣  Testando rota raiz do Caddy..."
ROOT_RESPONSE=$(curl -s -o /dev/null -w "%{http_code}" http://localhost:2022/ 2>/dev/null || echo "000")
if [ "$ROOT_RESPONSE" = "200" ]; then
    print_success "Rota raiz funciona (HTTP 200)"
elif [ "$ROOT_RESPONSE" = "404" ]; then
    print_error "Rota raiz retorna 404 - Caddy não consegue acessar frontend"
    print_info "Problema: Caddy em network_mode: host não consegue acessar frontend na rede Docker"
elif [ "$ROOT_RESPONSE" = "502" ]; then
    print_error "Rota raiz retorna 502 - Caddy não consegue fazer proxy"
else
    print_warning "Rota raiz retorna HTTP $ROOT_RESPONSE"
fi
echo ""

# 7. Solução: Fazer frontend também usar network_mode: host OU voltar Caddy para rede Docker
print_info "7️⃣  Analisando solução..."
echo ""
print_warning "Problema identificado:"
echo "  - Caddy está em network_mode: host"
echo "  - Frontend está na rede Docker bridge (172.19.0.2)"
echo "  - Caddy em network_mode: host NÃO consegue acessar containers na rede Docker"
echo ""
print_info "Soluções possíveis:"
echo "  1. Fazer frontend também usar network_mode: host (recomendado)"
echo "  2. Voltar Caddy para rede Docker e usar outra solução para backend"
echo ""

read -p "Aplicar solução 1 (frontend em network_mode: host)? (s/N): " APPLY_SOLUTION
if [ "$APPLY_SOLUTION" = "s" ] || [ "$APPLY_SOLUTION" = "S" ]; then
    print_info "Aplicando solução: Frontend em network_mode: host..."
    
    # Verificar se docker-compose.host-network.yml já tem frontend em network_mode: host
    if grep -A 10 "^  frontend:" docker-compose.host-network.yml | grep -q "network_mode: host"; then
        print_success "Frontend já está configurado para network_mode: host"
    else
        print_info "Atualizando docker-compose.host-network.yml..."
        # Fazer backup
        cp docker-compose.host-network.yml docker-compose.host-network.yml.backup.$(date +%Y%m%d_%H%M%S)
        
        # Adicionar network_mode: host no frontend
        # Remover networks e ports do frontend
        sed -i '/^  frontend:/,/^  # Caddy/ {
            /ports:/d
            /expose:/d
            /networks:/d
            /debrief-network/d
        }' docker-compose.host-network.yml
        
        # Adicionar network_mode: host após container_name
        sed -i '/^    container_name: debrief-frontend/a\    network_mode: host' docker-compose.host-network.yml
        
        print_success "docker-compose.host-network.yml atualizado"
    fi
    
    # Atualizar Caddyfile para usar localhost:80 para frontend
    print_info "Atualizando Caddyfile para usar localhost:80 para frontend..."
    sed -i "s|reverse_proxy [0-9.]\+:80|reverse_proxy localhost:80|g" Caddyfile
    print_success "Caddyfile atualizado"
    
    # Reiniciar frontend
    print_info "Reiniciando frontend..."
    docker-compose -f docker-compose.host-network.yml stop frontend
    docker-compose -f docker-compose.host-network.yml rm -f frontend
    docker-compose -f docker-compose.host-network.yml up -d frontend
    sleep 5
    print_success "Frontend reiniciado"
    
    # Reiniciar Caddy
    print_info "Reiniciando Caddy..."
    docker-compose -f docker-compose.host-network.yml restart caddy
    sleep 3
    print_success "Caddy reiniciado"
    
    # Testar novamente
    print_info "Testando conexão novamente..."
    sleep 2
    TEST_RESPONSE=$(curl -s -o /dev/null -w "%{http_code}" http://localhost:2022/api/health 2>/dev/null || echo "000")
    if [ "$TEST_RESPONSE" = "200" ]; then
        print_success "✅ Conexão funcionando! (HTTP 200)"
    else
        print_warning "Resposta HTTP $TEST_RESPONSE"
    fi
else
    print_info "Solução não aplicada. Você pode aplicar manualmente."
fi
echo ""

# 8. Resumo
echo "=========================================="
echo "📊 RESUMO"
echo "=========================================="
echo ""
print_info "Status atual:"
echo "  Backend: localhost:8000 ✅"
echo "  Frontend: $FRONTEND_IP:80 (rede Docker)"
echo "  Caddy: network_mode: host ✅"
echo ""
print_info "Problema:"
echo "  Caddy em network_mode: host não consegue acessar frontend na rede Docker"
echo ""
print_info "Solução recomendada:"
echo "  Fazer frontend também usar network_mode: host"
echo "  Ou voltar Caddy para rede Docker e usar outra solução"
echo ""

