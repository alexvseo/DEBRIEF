#!/bin/bash

# Script para Corrigir Problema da Porta 80 do Frontend
# Execute no servidor: ./corrigir-porta-80-frontend.sh

echo "=========================================="
echo "🔧 CORRIGIR PORTA 80 DO FRONTEND"
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

# 1. Verificar o que está usando a porta 80
print_info "1️⃣  Verificando o que está usando a porta 80..."
if netstat -tlnp 2>/dev/null | grep -q ":80.*LISTEN" || ss -tlnp 2>/dev/null | grep -q ":80"; then
    print_warning "Porta 80 está em uso"
    print_info "Processos usando porta 80:"
    netstat -tlnp 2>/dev/null | grep ":80" || ss -tlnp 2>/dev/null | grep ":80"
    echo ""
    
    # Verificar se é docker-proxy
    if netstat -tlnp 2>/dev/null | grep ":80" | grep -q "docker-prox" || ss -tlnp 2>/dev/null | grep ":80" | grep -q "docker-prox"; then
        print_warning "Porta 80 está sendo usada por docker-proxy"
        print_info "Isso pode ser de um container antigo ou outro serviço"
        print_info "Verificando containers Docker..."
        docker ps -a | grep -E "80|frontend" | head -5
    fi
else
    print_success "Porta 80 está livre"
fi
echo ""

# 2. Parar todos os containers
print_info "2️⃣  Parando todos os containers..."
docker-compose -f docker-compose.host-network.yml down
print_success "Containers parados"
echo ""

# 3. Verificar se porta 80 está livre agora
print_info "3️⃣  Verificando se porta 80 está livre..."
sleep 3
if netstat -tlnp 2>/dev/null | grep -q ":80.*LISTEN" || ss -tlnp 2>/dev/null | grep -q ":80"; then
    print_error "Porta 80 AINDA está em uso após parar containers"
    print_info "Pode ser outro serviço (nginx, apache, etc)"
    print_info "Verificando processos..."
    lsof -i :80 2>/dev/null | head -10 || fuser 80/tcp 2>/dev/null || echo "Não foi possível identificar processo"
    
    read -p "Deseja parar o processo que está usando a porta 80? (s/N): " KILL_PROCESS
    if [ "$KILL_PROCESS" = "s" ] || [ "$KILL_PROCESS" = "S" ]; then
        print_info "Parando processos na porta 80..."
        fuser -k 80/tcp 2>/dev/null || true
        sleep 2
        if ! (netstat -tlnp 2>/dev/null | grep -q ":80.*LISTEN" || ss -tlnp 2>/dev/null | grep -q ":80"); then
            print_success "Porta 80 está livre agora"
        else
            print_error "Ainda não conseguiu liberar porta 80"
        fi
    fi
else
    print_success "Porta 80 está livre"
fi
echo ""

# 4. Iniciar containers na ordem correta
print_info "4️⃣  Iniciando containers na ordem correta..."
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

# Iniciar frontend
print_info "Iniciando frontend..."
docker-compose -f docker-compose.host-network.yml up -d frontend
sleep 5

# Verificar se frontend está rodando
FRONTEND_STATUS=$(docker inspect debrief-frontend --format='{{.State.Status}}' 2>/dev/null || echo "not_found")
if [ "$FRONTEND_STATUS" = "running" ]; then
    print_success "Frontend está rodando"
    
    # Verificar se porta 80 está em uso pelo frontend
    sleep 3
    if netstat -tlnp 2>/dev/null | grep -q ":80.*LISTEN" || ss -tlnp 2>/dev/null | grep -q ":80"; then
        print_success "Porta 80 está em uso (provavelmente pelo frontend)"
    else
        print_warning "Porta 80 não está em uso ainda"
    fi
else
    print_error "Frontend não está rodando (status: $FRONTEND_STATUS)"
    print_info "Ver logs: docker-compose -f docker-compose.host-network.yml logs frontend"
fi

# Iniciar Caddy
print_info "Iniciando Caddy..."
docker-compose -f docker-compose.host-network.yml up -d caddy
sleep 3
print_success "Caddy iniciado"
echo ""

# 5. Testar conexões
print_info "5️⃣  Testando conexões..."
sleep 3

FRONTEND_RESPONSE=$(curl -s -o /dev/null -w "%{http_code}" http://localhost:80/ 2>/dev/null || echo "000")
if [ "$FRONTEND_RESPONSE" = "200" ]; then
    print_success "Frontend responde em localhost:80 (HTTP 200)"
elif [ "$FRONTEND_RESPONSE" = "301" ] || [ "$FRONTEND_RESPONSE" = "302" ]; then
    print_warning "Frontend retorna redirecionamento (HTTP $FRONTEND_RESPONSE) - pode ser normal"
else
    print_warning "Frontend retorna HTTP $FRONTEND_RESPONSE"
fi

CADDY_FRONTEND_RESPONSE=$(curl -s -o /dev/null -w "%{http_code}" http://localhost:2022/ 2>/dev/null || echo "000")
if [ "$CADDY_FRONTEND_RESPONSE" = "200" ]; then
    print_success "Caddy Frontend funciona (HTTP 200)"
elif [ "$CADDY_FRONTEND_RESPONSE" = "301" ] || [ "$CADDY_FRONTEND_RESPONSE" = "302" ]; then
    print_warning "Caddy Frontend retorna redirecionamento (HTTP $CADDY_FRONTEND_RESPONSE) - pode ser normal"
else
    print_warning "Caddy Frontend retorna HTTP $CADDY_FRONTEND_RESPONSE"
fi
echo ""

# 6. Resumo
echo "=========================================="
if [ "$FRONTEND_STATUS" = "running" ]; then
    print_success "✅ Frontend está rodando!"
    echo ""
    print_info "Acesse a aplicação:"
    echo "  🌐 http://82.25.92.217:2022/login"
else
    print_warning "⚠️  Frontend ainda não está rodando corretamente"
    echo ""
    print_info "Verifique:"
    echo "  1. Logs: docker-compose -f docker-compose.host-network.yml logs frontend"
    echo "  2. Porta 80: netstat -tlnp | grep :80"
    echo "  3. Status: docker-compose -f docker-compose.host-network.yml ps frontend"
fi
echo ""

