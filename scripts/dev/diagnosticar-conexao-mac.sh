#!/bin/bash

################################################################################
# Script para diagnosticar problemas de conexão do Mac ao banco remoto
# Específico para Mac Mini
################################################################################

set -e

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

echo "🔍 Diagnosticando conexão do Mac Mini ao banco remoto..."
echo ""

DB_HOST="82.25.92.217"
DB_PORT="5432"

# 1. Verificar conectividade básica (ping)
print_info "1️⃣  Testando conectividade básica (ping)..."
if ping -c 3 -W 2000 "$DB_HOST" > /dev/null 2>&1; then
    print_success "Servidor $DB_HOST está acessível via ping"
else
    print_error "Não foi possível fazer ping em $DB_HOST"
    print_warning "Verifique sua conexão de internet"
    exit 1
fi
echo ""

# 2. Verificar se porta está aberta (telnet/nc)
print_info "2️⃣  Testando porta $DB_PORT com telnet/nc..."
if command -v nc &> /dev/null; then
    if timeout 5 nc -z -v "$DB_HOST" "$DB_PORT" 2>&1 | grep -q "succeeded\|open"; then
        print_success "Porta $DB_PORT está aberta e acessível"
    else
        print_error "Porta $DB_PORT não está acessível"
        print_info "Tentando método alternativo..."
        
        # Tentar com timeout bash
        if timeout 5 bash -c "echo > /dev/tcp/$DB_HOST/$DB_PORT" 2>/dev/null; then
            print_success "Porta $DB_PORT está acessível (método alternativo)"
        else
            print_error "Porta $DB_PORT definitivamente não está acessível"
        fi
    fi
elif timeout 5 bash -c "echo > /dev/tcp/$DB_HOST/$DB_PORT" 2>/dev/null; then
    print_success "Porta $DB_PORT está acessível"
else
    print_error "Porta $DB_PORT não está acessível"
fi
echo ""

# 3. Verificar firewall do Mac
print_info "3️⃣  Verificando firewall do Mac..."
FIREWALL_STATUS=$(/usr/libexec/ApplicationFirewall/socketfilterfw --getglobalstate 2>/dev/null | grep -i "enabled\|disabled" || echo "unknown")
if echo "$FIREWALL_STATUS" | grep -qi "enabled"; then
    print_warning "Firewall do Mac está ATIVO"
    print_info "Isso pode estar bloqueando conexões de saída"
    print_info "Para verificar regras: sudo /usr/libexec/ApplicationFirewall/socketfilterfw --listapps"
else
    print_success "Firewall do Mac está desativado ou não configurado"
fi
echo ""

# 4. Verificar se há proxy configurado
print_info "4️⃣  Verificando configurações de proxy..."
if [ -n "$http_proxy" ] || [ -n "$HTTP_PROXY" ] || [ -n "$https_proxy" ] || [ -n "$HTTPS_PROXY" ]; then
    print_warning "Proxy HTTP/HTTPS configurado:"
    [ -n "$http_proxy" ] && echo "  http_proxy: $http_proxy"
    [ -n "$HTTP_PROXY" ] && echo "  HTTP_PROXY: $HTTP_PROXY"
    [ -n "$https_proxy" ] && echo "  https_proxy: $https_proxy"
    [ -n "$HTTPS_PROXY" ] && echo "  HTTPS_PROXY: $HTTPS_PROXY"
    print_info "Proxy pode interferir em conexões diretas ao banco"
else
    print_success "Nenhum proxy HTTP/HTTPS configurado"
fi
echo ""

# 5. Testar conexão com psql diretamente
print_info "5️⃣  Testando conexão direta com psql..."
if command -v psql &> /dev/null; then
    export PGPASSWORD="<redacted-db-password>"
    
    if timeout 10 psql -h "$DB_HOST" -p "$DB_PORT" -U postgres -d dbrief -c "SELECT 1;" -t 2>&1 | grep -q "1"; then
        print_success "Conexão com psql funcionou!"
        DB_VERSION=$(psql -h "$DB_HOST" -p "$DB_PORT" -U postgres -d dbrief -c "SELECT version();" -t 2>/dev/null | head -n1 | xargs)
        print_info "Versão PostgreSQL: ${DB_VERSION:0:60}..."
    else
        ERROR_MSG=$(timeout 10 psql -h "$DB_HOST" -p "$DB_PORT" -U postgres -d dbrief -c "SELECT 1;" 2>&1 | tail -n1)
        print_error "Falha na conexão com psql"
        print_info "Erro: $ERROR_MSG"
    fi
    unset PGPASSWORD
else
    print_warning "psql não encontrado. Pulando teste direto."
fi
echo ""

# 6. Verificar rota de rede
print_info "6️⃣  Verificando rota de rede..."
if command -v traceroute &> /dev/null; then
    print_info "Traceroute para $DB_HOST (primeiros 5 hops):"
    timeout 30 traceroute -m 5 "$DB_HOST" 2>/dev/null | head -n 6 || print_warning "Traceroute falhou ou demorou muito"
elif command -v tracepath &> /dev/null; then
    print_info "Tracepath para $DB_HOST:"
    timeout 30 tracepath "$DB_HOST" 2>/dev/null | head -n 10 || print_warning "Tracepath falhou"
else
    print_warning "Ferramentas de traceroute não encontradas"
fi
echo ""

# 7. Verificar DNS
print_info "7️⃣  Verificando resolução DNS..."
if nslookup "$DB_HOST" > /dev/null 2>&1 || host "$DB_HOST" > /dev/null 2>&1; then
    IP=$(nslookup "$DB_HOST" 2>/dev/null | grep -A1 "Name:" | tail -n1 | awk '{print $2}' || host "$DB_HOST" 2>/dev/null | grep "has address" | awk '{print $4}')
    if [ -n "$IP" ]; then
        print_success "DNS resolvido: $DB_HOST -> $IP"
    else
        print_warning "DNS resolvido, mas IP não encontrado"
    fi
else
    print_warning "Não foi possível resolver DNS (pode ser IP direto)"
fi
echo ""

# 8. Resumo e recomendações
echo "════════════════════════════════════════════════════════════"
print_info "📋 RESUMO E RECOMENDAÇÕES:"
echo ""

if timeout 5 bash -c "echo > /dev/tcp/$DB_HOST/$DB_PORT" 2>/dev/null; then
    print_success "✅ Porta $DB_PORT está acessível - conexão deve funcionar!"
    print_info "Próximo passo: Execute ./scripts/dev/iniciar-dev-local.sh"
else
    print_error "❌ Porta $DB_PORT NÃO está acessível"
    echo ""
    print_info "🔧 POSSÍVEIS SOLUÇÕES:"
    echo ""
    echo "1. Verificar firewall do servidor:"
    echo "   - Servidor precisa permitir conexões de entrada na porta 5432"
    echo "   - Verificar ufw/iptables no servidor"
    echo ""
    echo "2. Verificar PostgreSQL no servidor:"
    echo "   - postgresql.conf: listen_addresses = '*'"
    echo "   - pg_hba.conf: permitir conexões do seu IP"
    echo ""
    echo "3. Verificar firewall do Mac:"
    echo "   - Sistema > Segurança > Firewall"
    echo "   - Pode precisar permitir conexões de saída"
    echo ""
    echo "4. Verificar se está em VPN ou rede restrita:"
    echo "   - Algumas redes corporativas bloqueiam portas específicas"
    echo ""
    echo "5. Testar de outro local/rede:"
    echo "   - Verificar se problema é específico da sua rede"
    echo ""
    print_info "Para mais ajuda, execute: ./scripts/dev/corrigir-conexao-mac.sh"
fi
echo ""

