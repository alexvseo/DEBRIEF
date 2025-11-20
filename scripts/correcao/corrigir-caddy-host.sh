#!/bin/bash

# Script para Corrigir Problema de DNS do Caddy
# Execute no servidor: ./corrigir-caddy-host.sh

echo "=========================================="
echo "🔧 CORRIGIR PROBLEMA DE DNS DO CADDY"
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

# 1. Descobrir IP do host
print_info "1️⃣  Descobrindo IP do host..."
HOST_IP=$(hostname -I | awk '{print $1}')
print_info "IP do host: $HOST_IP"
echo ""

# 2. Descobrir gateway Docker
print_info "2️⃣  Descobrindo gateway Docker..."
DOCKER_GATEWAY=$(docker network inspect debrief_debrief-network 2>/dev/null | grep -A 1 Gateway | grep Gateway | head -1 | awk '{print $2}' | tr -d '"' | tr -d ',')
if [ -z "$DOCKER_GATEWAY" ]; then
    # Tentar método alternativo
    DOCKER_GATEWAY=$(docker network inspect debrief_debrief-network 2>/dev/null | grep -oP '"Gateway": "\K[^"]+' | head -1)
fi

if [ -n "$DOCKER_GATEWAY" ]; then
    print_info "Gateway Docker: $DOCKER_GATEWAY"
else
    print_warning "Gateway Docker não encontrado, usando IP do host"
    DOCKER_GATEWAY="$HOST_IP"
fi
echo ""

# 3. Testar qual IP funciona do container Caddy
print_info "3️⃣  Testando qual IP o Caddy consegue acessar..."
if docker ps --filter "name=debrief-caddy" --format "{{.Names}}" | grep -q debrief-caddy; then
    # Testar host.docker.internal
    print_info "   Testando host.docker.internal:2025..."
    if docker exec debrief-caddy timeout 2 bash -c "echo > /dev/tcp/host.docker.internal/2025" 2>/dev/null; then
        print_success "   host.docker.internal:2025 funciona!"
        USE_HOST="host.docker.internal:2025"
    else
        print_warning "   host.docker.internal:2025 não funciona"
        
        # Testar gateway Docker
        print_info "   Testando $DOCKER_GATEWAY:2025..."
        if docker exec debrief-caddy timeout 2 bash -c "echo > /dev/tcp/$DOCKER_GATEWAY/2025" 2>/dev/null; then
            print_success "   $DOCKER_GATEWAY:2025 funciona!"
            USE_HOST="$DOCKER_GATEWAY:2025"
        else
            print_warning "   $DOCKER_GATEWAY:2025 não funciona"
            
            # Testar IP do host
            print_info "   Testando $HOST_IP:2025..."
            if docker exec debrief-caddy timeout 2 bash -c "echo > /dev/tcp/$HOST_IP/2025" 2>/dev/null; then
                print_success "   $HOST_IP:2025 funciona!"
                USE_HOST="$HOST_IP:2025"
            else
                print_error "   Nenhum IP funciona!"
                print_info "   Tentando localhost:8000 (porta interna do backend)..."
                if docker exec debrief-caddy timeout 2 bash -c "echo > /dev/tcp/localhost/8000" 2>/dev/null; then
                    print_success "   localhost:8000 funciona!"
                    USE_HOST="localhost:8000"
                else
                    print_error "   localhost:8000 também não funciona"
                    USE_HOST=""
                fi
            fi
        fi
    fi
else
    print_warning "Container Caddy não está rodando"
    USE_HOST="$DOCKER_GATEWAY:2025"
fi
echo ""

# 4. Atualizar Caddyfile
if [ -n "$USE_HOST" ]; then
    print_info "4️⃣  Atualizando Caddyfile para usar: $USE_HOST"
    
    # Fazer backup
    cp Caddyfile Caddyfile.backup.$(date +%Y%m%d_%H%M%S)
    
    # Atualizar Caddyfile
    sed -i "s|reverse_proxy host.docker.internal:2025|reverse_proxy $USE_HOST|g" Caddyfile
    
    print_success "Caddyfile atualizado"
    echo ""
    print_info "Mudança aplicada:"
    grep "reverse_proxy" Caddyfile | head -1
    echo ""
else
    print_error "Não foi possível determinar IP válido"
    exit 1
fi

# 5. Reiniciar Caddy
print_info "5️⃣  Reiniciando Caddy..."
docker-compose -f docker-compose.host-network.yml restart caddy
sleep 3
print_success "Caddy reiniciado"
echo ""

# 6. Testar conexão
print_info "6️⃣  Testando conexão..."
sleep 2
TEST_RESPONSE=$(curl -s -o /dev/null -w "%{http_code}" http://localhost:2022/api/health 2>/dev/null || echo "000")
if [ "$TEST_RESPONSE" = "200" ]; then
    print_success "✅ Conexão funcionando! (HTTP 200)"
    curl -s http://localhost:2022/api/health | head -3
elif [ "$TEST_RESPONSE" = "502" ]; then
    print_error "❌ Ainda há erro 502"
    print_info "Verifique logs: docker-compose -f docker-compose.host-network.yml logs caddy | tail -20"
else
    print_warning "Resposta HTTP $TEST_RESPONSE"
fi
echo ""

# 7. Resumo
echo "=========================================="
if [ "$TEST_RESPONSE" = "200" ]; then
    print_success "✅ Problema resolvido!"
    echo ""
    print_info "Caddyfile atualizado para usar: $USE_HOST"
    echo ""
    print_info "Acesse a aplicação:"
    echo "  🌐 http://82.25.92.217:2022/login"
else
    print_warning "⚠️  Verifique os logs para mais detalhes"
    echo ""
    print_info "Caddyfile foi atualizado para usar: $USE_HOST"
    echo ""
    print_info "Se ainda não funcionar, tente:"
    echo "  1. Ver logs: docker-compose -f docker-compose.host-network.yml logs caddy"
    echo "  2. Verificar se backend está rodando: docker-compose -f docker-compose.host-network.yml ps backend"
    echo "  3. Testar backend diretamente: curl http://localhost:2025/health"
fi
echo ""

