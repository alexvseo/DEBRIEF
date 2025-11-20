#!/bin/bash

# Script para Aplicar Correção do Caddy
# Execute no servidor: ./aplicar-correcao-caddy.sh

echo "=========================================="
echo "🔧 APLICAR CORREÇÃO DO CADDY"
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

# 1. Parar Caddy atual
print_info "1️⃣  Parando Caddy atual..."
docker-compose -f docker-compose.host-network.yml stop caddy
docker-compose -f docker-compose.host-network.yml rm -f caddy
print_success "Caddy parado e removido"
echo ""

# 2. Verificar se porta 2022 está livre
print_info "2️⃣  Verificando se porta 2022 está livre..."
if netstat -tlnp 2>/dev/null | grep -q ":2022.*LISTEN" || ss -tlnp 2>/dev/null | grep -q ":2022"; then
    print_warning "Porta 2022 ainda está em uso"
    print_info "Aguardando 3 segundos..."
    sleep 3
    if netstat -tlnp 2>/dev/null | grep -q ":2022.*LISTEN" || ss -tlnp 2>/dev/null | grep -q ":2022"; then
        print_error "Porta 2022 ainda está em uso. Libere manualmente."
        exit 1
    fi
fi
print_success "Porta 2022 está livre"
echo ""

# 3. Verificar Caddyfile
print_info "3️⃣  Verificando Caddyfile..."
if grep -q "^:2022" Caddyfile; then
    print_success "Caddyfile está configurado para porta 2022"
else
    print_error "Caddyfile não está configurado para porta 2022"
    print_info "Atualizando Caddyfile..."
    sed -i 's/^:80 {/:2022 {/' Caddyfile
    print_success "Caddyfile atualizado"
fi
echo ""

# 4. Descobrir IP do frontend
print_info "4️⃣  Descobrindo IP do frontend..."
FRONTEND_IP=$(docker inspect debrief-frontend --format='{{range .NetworkSettings.Networks}}{{.IPAddress}}{{end}}' 2>/dev/null)
if [ -z "$FRONTEND_IP" ]; then
    print_error "Não foi possível descobrir IP do frontend"
    exit 1
fi
print_success "IP do frontend: $FRONTEND_IP"
echo ""

# 5. Atualizar Caddyfile com IP do frontend
print_info "5️⃣  Atualizando Caddyfile com IP do frontend..."
sed -i "s|reverse_proxy [0-9.]\+:80|reverse_proxy $FRONTEND_IP:80|g" Caddyfile
print_success "Caddyfile atualizado"
echo ""

# 6. Verificar docker-compose.host-network.yml
print_info "6️⃣  Verificando docker-compose.host-network.yml..."
if grep -q "network_mode: host" docker-compose.host-network.yml | grep -A 5 "caddy:"; then
    print_success "docker-compose.host-network.yml está configurado corretamente"
else
    print_warning "Verificando se Caddy tem network_mode: host..."
    if grep -A 10 "^  caddy:" docker-compose.host-network.yml | grep -q "network_mode: host"; then
        print_success "Caddy tem network_mode: host configurado"
    else
        print_error "Caddy NÃO tem network_mode: host no docker-compose.host-network.yml"
        print_info "Atualize o arquivo manualmente ou faça pull das atualizações"
    fi
fi
echo ""

# 7. Iniciar Caddy com nova configuração
print_info "7️⃣  Iniciando Caddy com network_mode: host..."
docker-compose -f docker-compose.host-network.yml up -d caddy
sleep 3
print_success "Caddy iniciado"
echo ""

# 8. Verificar se Caddy está em network_mode: host
print_info "8️⃣  Verificando se Caddy está em network_mode: host..."
CADDY_NETWORK=$(docker inspect debrief-caddy --format='{{.HostConfig.NetworkMode}}' 2>/dev/null)
if [ "$CADDY_NETWORK" = "host" ]; then
    print_success "✅ Caddy está em network_mode: host"
else
    print_error "❌ Caddy NÃO está em network_mode: host (atual: $CADDY_NETWORK)"
    print_info "Pode ser necessário fazer pull das atualizações: git pull"
fi
echo ""

# 9. Verificar se Caddy está escutando na porta 2022
print_info "9️⃣  Verificando se Caddy está escutando na porta 2022..."
sleep 2
if netstat -tlnp 2>/dev/null | grep -q ":2022.*LISTEN" || ss -tlnp 2>/dev/null | grep -q ":2022"; then
    print_success "Porta 2022 está em uso (Caddy está escutando)"
else
    print_warning "Porta 2022 não está em uso ainda (aguardando...)"
    sleep 3
    if netstat -tlnp 2>/dev/null | grep -q ":2022.*LISTEN" || ss -tlnp 2>/dev/null | grep -q ":2022"; then
        print_success "Porta 2022 está em uso agora"
    else
        print_error "Porta 2022 ainda não está em uso"
    fi
fi
echo ""

# 10. Testar conexão
print_info "🔟 Testando conexão..."
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

# 11. Resumo
echo "=========================================="
if [ "$CADDY_NETWORK" = "host" ] && [ "$TEST_RESPONSE" = "200" ]; then
    print_success "✅ Correção aplicada com sucesso!"
    echo ""
    print_info "Caddy está configurado corretamente:"
    echo "  - network_mode: host ✅"
    echo "  - Escutando na porta 2022 ✅"
    echo "  - Backend: localhost:8000 ✅"
    echo "  - Frontend: $FRONTEND_IP:80 ✅"
    echo ""
    print_info "Acesse a aplicação:"
    echo "  🌐 http://82.25.92.217:2022/login"
elif [ "$CADDY_NETWORK" = "host" ]; then
    print_warning "⚠️  Caddy está em network_mode: host, mas conexão ainda não funciona"
    echo ""
    print_info "Verifique:"
    echo "  1. Logs do Caddy: docker-compose -f docker-compose.host-network.yml logs caddy"
    echo "  2. Se backend está rodando: curl http://localhost:8000/health"
    echo "  3. Se frontend está acessível: curl http://$FRONTEND_IP:80"
else
    print_error "❌ Caddy não está em network_mode: host"
    echo ""
    print_info "Soluções:"
    echo "  1. Fazer pull: git pull"
    echo "  2. Verificar docker-compose.host-network.yml"
    echo "  3. Executar novamente: ./aplicar-correcao-caddy.sh"
fi
echo ""

