#!/bin/bash

# Script para Corrigir Problema de Rede do Caddy
# Descobre IP do frontend e atualiza Caddyfile
# Execute no servidor: ./corrigir-caddy-network.sh

echo "=========================================="
echo "🔧 CORRIGIR REDE DO CADDY"
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

# 1. Descobrir IP do container frontend
print_info "1️⃣  Descobrindo IP do container frontend..."
FRONTEND_IP=$(docker inspect debrief-frontend --format='{{range .NetworkSettings.Networks}}{{.IPAddress}}{{end}}' 2>/dev/null)
if [ -z "$FRONTEND_IP" ]; then
    print_error "Não foi possível descobrir IP do frontend"
    print_info "Verificando se container está rodando..."
    docker ps --filter "name=debrief-frontend"
    exit 1
fi
print_success "IP do frontend: $FRONTEND_IP"
echo ""

# 2. Fazer backup do Caddyfile
print_info "2️⃣  Fazendo backup do Caddyfile..."
cp Caddyfile Caddyfile.backup.$(date +%Y%m%d_%H%M%S)
print_success "Backup criado"
echo ""

# 3. Atualizar Caddyfile
print_info "3️⃣  Atualizando Caddyfile..."
sed -i "s|reverse_proxy 172.19.0.2:80|reverse_proxy $FRONTEND_IP:80|g" Caddyfile
print_success "Caddyfile atualizado"
echo ""

# 4. Verificar mudanças
print_info "4️⃣  Verificando mudanças no Caddyfile..."
echo "Backend:"
grep "reverse_proxy.*localhost:8000" Caddyfile
echo "Frontend:"
grep "reverse_proxy.*$FRONTEND_IP:80" Caddyfile
echo ""

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
    print_info "Caddyfile atualizado:"
    echo "  Backend: localhost:8000"
    echo "  Frontend: $FRONTEND_IP:80"
    echo ""
    print_info "Acesse a aplicação:"
    echo "  🌐 http://82.25.92.217:2022/login"
else
    print_warning "⚠️  Verifique os logs para mais detalhes"
    echo ""
    print_info "Caddyfile foi atualizado para usar:"
    echo "  Backend: localhost:8000"
    echo "  Frontend: $FRONTEND_IP:80"
fi
echo ""

