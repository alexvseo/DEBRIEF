#!/bin/bash

# Script para Corrigir Erro 502 Rapidamente
# Execute no servidor: ./corrigir-502.sh

echo "=========================================="
echo "🔧 CORRIGIR ERRO 502"
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

# 1. Fazer pull das atualizações
print_info "1️⃣  Fazendo pull das atualizações..."
git pull
if [ $? -eq 0 ]; then
    print_success "Pull concluído"
else
    print_error "Erro ao fazer pull"
    exit 1
fi
echo ""

# 2. Reiniciar Caddy para aplicar novo Caddyfile
print_info "2️⃣  Reiniciando Caddy para aplicar novo Caddyfile..."
docker-compose -f docker-compose.host-network.yml restart caddy
sleep 3
print_success "Caddy reiniciado"
echo ""

# 3. Verificar se Caddy está rodando
print_info "3️⃣  Verificando se Caddy está rodando..."
if docker ps --filter "name=debrief-caddy" --format "{{.Names}}" | grep -q debrief-caddy; then
    print_success "Caddy está rodando"
else
    print_error "Caddy não está rodando"
    print_info "Iniciando Caddy..."
    docker-compose -f docker-compose.host-network.yml up -d caddy
fi
echo ""

# 4. Testar conexão
print_info "4️⃣  Testando conexão..."
sleep 2
TEST_RESPONSE=$(curl -s -o /dev/null -w "%{http_code}" http://localhost:2022/api/health 2>/dev/null || echo "000")
if [ "$TEST_RESPONSE" = "200" ]; then
    print_success "✅ Conexão funcionando! (HTTP 200)"
elif [ "$TEST_RESPONSE" = "502" ]; then
    print_error "❌ Ainda há erro 502"
    print_info "Execute diagnóstico: ./diagnosticar-502.sh"
else
    print_warning "Resposta HTTP $TEST_RESPONSE"
fi
echo ""

# 5. Resumo
echo "=========================================="
if [ "$TEST_RESPONSE" = "200" ]; then
    print_success "✅ Correção aplicada com sucesso!"
    echo ""
    print_info "Acesse a aplicação:"
    echo "  🌐 http://82.25.92.217:2022/login"
    echo ""
    print_info "Se ainda houver erro, limpe o cache do navegador (Ctrl+Shift+Delete)"
else
    print_warning "⚠️  Verifique os logs:"
    echo "  docker-compose -f docker-compose.host-network.yml logs caddy"
    echo "  docker-compose -f docker-compose.host-network.yml logs backend"
    echo ""
    print_info "Execute diagnóstico completo:"
    echo "  ./diagnosticar-502.sh"
fi
echo ""

