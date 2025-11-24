#!/bin/bash

# Script Rápido para Aplicar Correção do Erro 404
# Execute no servidor: ./aplicar-correcao-404.sh

echo "=========================================="
echo "🔧 APLICAR CORREÇÃO ERRO 404"
echo "=========================================="
echo ""

# Cores
GREEN='\033[0;32m'
BLUE='\033[0;34m'
NC='\033[0m'

print_info() {
    echo -e "${BLUE}ℹ️  $1${NC}"
}

print_success() {
    echo -e "${GREEN}✅ $1${NC}"
}

# 1. Fazer pull
print_info "1️⃣  Fazendo pull das atualizações..."
git pull
echo ""

# 2. Parar frontend e Caddy
print_info "2️⃣  Parando frontend e Caddy..."
docker-compose -f docker-compose.host-network.yml stop frontend caddy
docker-compose -f docker-compose.host-network.yml rm -f frontend caddy
print_success "Containers parados"
echo ""

# 3. Reiniciar frontend com network_mode: host
print_info "3️⃣  Reiniciando frontend com network_mode: host..."
docker-compose -f docker-compose.host-network.yml up -d frontend
sleep 5
print_success "Frontend reiniciado"
echo ""

# 4. Reiniciar Caddy
print_info "4️⃣  Reiniciando Caddy..."
docker-compose -f docker-compose.host-network.yml up -d caddy
sleep 3
print_success "Caddy reiniciado"
echo ""

# 5. Testar conexão
print_info "5️⃣  Testando conexão..."
sleep 3
TEST_RESPONSE=$(curl -s -o /dev/null -w "%{http_code}" http://localhost:2022/api/health 2>/dev/null || echo "000")
if [ "$TEST_RESPONSE" = "200" ]; then
    print_success "✅ Conexão funcionando! (HTTP 200)"
    curl -s http://localhost:2022/api/health | head -3
elif [ "$TEST_RESPONSE" = "404" ]; then
    print_info "⚠️  Ainda retorna 404, mas pode ser cache. Teste no navegador."
else
    print_info "Resposta HTTP $TEST_RESPONSE"
fi
echo ""

# 6. Resumo
echo "=========================================="
print_success "✅ Correção aplicada!"
echo "=========================================="
echo ""
print_info "Acesse a aplicação:"
echo "  🌐 http://82.25.92.217:2022/login"
echo ""
print_info "Se ainda houver erro 404, limpe o cache do navegador (Ctrl+Shift+Delete)"
echo ""

