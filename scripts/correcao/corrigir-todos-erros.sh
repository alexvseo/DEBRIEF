#!/bin/bash

# Script para Corrigir Todos os Erros Encontrados
# Execute no servidor: ./corrigir-todos-erros.sh

echo "=========================================="
echo "🔧 CORRIGIR TODOS OS ERROS"
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

# 2. Parar todos os containers
print_info "2️⃣  Parando todos os containers..."
docker-compose -f docker-compose.host-network.yml down
print_success "Containers parados"
echo ""

# 3. Verificar docker-compose.host-network.yml
print_info "3️⃣  Verificando docker-compose.host-network.yml..."
if docker-compose -f docker-compose.host-network.yml config > /dev/null 2>&1; then
    print_success "docker-compose.host-network.yml está válido"
else
    print_error "docker-compose.host-network.yml tem erros"
    docker-compose -f docker-compose.host-network.yml config 2>&1 | head -5
    exit 1
fi
echo ""

# 4. Iniciar backend
print_info "4️⃣  Iniciando backend..."
docker-compose -f docker-compose.host-network.yml up -d backend
sleep 10
print_success "Backend iniciado"
echo ""

# 5. Verificar se backend está healthy
print_info "5️⃣  Verificando se backend está healthy..."
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

# 6. Iniciar frontend
print_info "6️⃣  Iniciando frontend..."
docker-compose -f docker-compose.host-network.yml up -d frontend
sleep 5
print_success "Frontend iniciado"
echo ""

# 7. Verificar se frontend está em network_mode: host
print_info "7️⃣  Verificando se frontend está em network_mode: host..."
FRONTEND_NETWORK=$(docker inspect debrief-frontend --format='{{.HostConfig.NetworkMode}}' 2>/dev/null)
if [ "$FRONTEND_NETWORK" = "host" ]; then
    print_success "Frontend está em network_mode: host"
else
    print_error "Frontend NÃO está em network_mode: host (atual: $FRONTEND_NETWORK)"
    print_info "Reiniciando frontend..."
    docker-compose -f docker-compose.host-network.yml stop frontend
    docker-compose -f docker-compose.host-network.yml rm -f frontend
    docker-compose -f docker-compose.host-network.yml up -d frontend
    sleep 5
    FRONTEND_NETWORK=$(docker inspect debrief-frontend --format='{{.HostConfig.NetworkMode}}' 2>/dev/null)
    if [ "$FRONTEND_NETWORK" = "host" ]; then
        print_success "Frontend agora está em network_mode: host"
    else
        print_error "Ainda não está em network_mode: host"
    fi
fi
echo ""

# 8. Iniciar Caddy
print_info "8️⃣  Iniciando Caddy..."
docker-compose -f docker-compose.host-network.yml up -d caddy
sleep 3
print_success "Caddy iniciado"
echo ""

# 9. Verificar se Caddy está em network_mode: host
print_info "9️⃣  Verificando se Caddy está em network_mode: host..."
CADDY_NETWORK=$(docker inspect debrief-caddy --format='{{.HostConfig.NetworkMode}}' 2>/dev/null)
if [ "$CADDY_NETWORK" = "host" ]; then
    print_success "Caddy está em network_mode: host"
else
    print_error "Caddy NÃO está em network_mode: host (atual: $CADDY_NETWORK)"
fi
echo ""

# 10. Testar conexões
print_info "🔟 Testando conexões..."
sleep 5

# Backend
BACKEND_RESPONSE=$(curl -s -o /dev/null -w "%{http_code}" http://localhost:8000/health 2>/dev/null || echo "000")
if [ "$BACKEND_RESPONSE" = "200" ]; then
    print_success "Backend responde (HTTP 200)"
else
    print_error "Backend não responde (HTTP $BACKEND_RESPONSE)"
fi

# Frontend
FRONTEND_RESPONSE=$(curl -s -o /dev/null -w "%{http_code}" http://localhost:80/ 2>/dev/null || echo "000")
if [ "$FRONTEND_RESPONSE" = "200" ]; then
    print_success "Frontend responde (HTTP 200)"
elif [ "$FRONTEND_RESPONSE" = "301" ] || [ "$FRONTEND_RESPONSE" = "302" ]; then
    print_warning "Frontend retorna redirecionamento (HTTP $FRONTEND_RESPONSE) - pode ser normal"
else
    print_error "Frontend não responde (HTTP $FRONTEND_RESPONSE)"
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
else
    print_warning "Caddy Frontend retorna HTTP $CADDY_FRONTEND_RESPONSE"
fi
echo ""

# 11. Verificar logs do backend para erro 500
print_info "1️⃣1️⃣  Verificando logs do backend (erro 500 no login)..."
echo "----------------------------------------"
docker-compose -f docker-compose.host-network.yml logs --tail=20 backend 2>&1 | grep -i "error\|exception\|traceback\|500" | tail -10 || echo "Nenhum erro encontrado nos logs recentes"
echo ""

# 12. Resumo
echo "=========================================="
echo "📊 RESUMO"
echo "=========================================="
echo ""

if [ "$BACKEND_RESPONSE" = "200" ] && [ "$CADDY_API_RESPONSE" = "200" ] && [ "$CADDY_FRONTEND_RESPONSE" = "200" ]; then
    print_success "✅ Tudo está funcionando!"
    echo ""
    print_info "Acesse a aplicação:"
    echo "  🌐 http://82.25.92.217:2022/login"
    echo ""
    if [ "$FRONTEND_NETWORK" != "host" ] || [ "$CADDY_NETWORK" != "host" ]; then
        print_warning "⚠️  Alguns containers não estão em network_mode: host"
        print_info "Execute novamente: ./corrigir-todos-erros.sh"
    fi
else
    print_warning "⚠️  Alguns problemas ainda persistem"
    echo ""
    print_info "Verifique:"
    echo "  1. Logs do backend: docker-compose -f docker-compose.host-network.yml logs backend | tail -50"
    echo "  2. Logs do Caddy: docker-compose -f docker-compose.host-network.yml logs caddy | tail -50"
    echo "  3. Execute diagnóstico: ./diagnosticar-conexao-completa.sh"
fi
echo ""

