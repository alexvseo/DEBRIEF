#!/bin/bash

################################################################################
# Script para tentar corrigir problemas de conexão do Mac ao banco remoto
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

echo "🔧 Tentando corrigir problemas de conexão do Mac ao banco remoto..."
echo ""

DB_HOST="82.25.92.217"
DB_PORT="5432"

# 1. Verificar e configurar firewall do Mac
print_info "1️⃣  Verificando firewall do Mac..."
FIREWALL_STATUS=$(/usr/libexec/ApplicationFirewall/socketfilterfw --getglobalstate 2>/dev/null | grep -i "enabled\|disabled" || echo "unknown")

if echo "$FIREWALL_STATUS" | grep -qi "enabled"; then
    print_warning "Firewall do Mac está ATIVO"
    print_info "O firewall do Mac geralmente NÃO bloqueia conexões de saída"
    print_info "Mas vamos verificar se há regras específicas bloqueando..."
    
    # Verificar regras
    RULES=$(/usr/libexec/ApplicationFirewall/socketfilterfw --listapps 2>/dev/null | grep -i "block\|deny" || echo "")
    if [ -n "$RULES" ]; then
        print_warning "Encontradas regras de bloqueio:"
        echo "$RULES"
    else
        print_success "Nenhuma regra de bloqueio encontrada"
    fi
else
    print_success "Firewall do Mac não está ativo"
fi
echo ""

# 2. Verificar se há processos bloqueando
print_info "2️⃣  Verificando processos que podem estar bloqueando conexões..."
if command -v lsof &> /dev/null; then
    BLOCKING=$(sudo lsof -i :5432 2>/dev/null || echo "")
    if [ -n "$BLOCKING" ]; then
        print_warning "Processos usando porta 5432 localmente:"
        echo "$BLOCKING"
        print_info "Isso não deve afetar conexões de saída, mas pode indicar conflito"
    else
        print_success "Nenhum processo local usando porta 5432"
    fi
else
    print_warning "lsof não encontrado. Pulando verificação."
fi
echo ""

# 3. Testar com diferentes métodos de conexão
print_info "3️⃣  Testando diferentes métodos de conexão..."

# Método 1: nc (netcat)
if command -v nc &> /dev/null; then
    print_info "Testando com nc (netcat)..."
    if timeout 5 nc -z -v "$DB_HOST" "$DB_PORT" 2>&1; then
        print_success "nc conseguiu conectar!"
    else
        print_warning "nc não conseguiu conectar"
    fi
fi
echo ""

# Método 2: telnet
if command -v telnet &> /dev/null; then
    print_info "Testando com telnet..."
    if echo "quit" | timeout 5 telnet "$DB_HOST" "$DB_PORT" 2>&1 | grep -q "Connected\|Escape"; then
        print_success "telnet conseguiu conectar!"
    else
        print_warning "telnet não conseguiu conectar"
    fi
fi
echo ""

# Método 3: curl (teste HTTP, mas pode indicar conectividade)
print_info "Testando conectividade geral com curl..."
if timeout 5 curl -s -o /dev/null -w "%{http_code}" "http://$DB_HOST" 2>/dev/null | grep -q "[0-9]"; then
    print_success "curl conseguiu acessar o servidor (conectividade OK)"
else
    print_warning "curl não conseguiu acessar o servidor"
fi
echo ""

# 4. Verificar configurações de rede do Mac
print_info "4️⃣  Verificando configurações de rede..."
print_info "Interfaces de rede ativas:"
ifconfig | grep -E "^[a-z]|inet " | grep -B1 "inet " | head -n 10
echo ""

# 5. Verificar se está em VPN
print_info "5️⃣  Verificando conexões VPN..."
VPN_CONNECTIONS=$(scutil --nc list 2>/dev/null | grep -i "connected" || echo "")
if [ -n "$VPN_CONNECTIONS" ]; then
    print_warning "VPN ativa detectada:"
    echo "$VPN_CONNECTIONS"
    print_info "VPN pode estar interferindo na conexão"
    print_info "Tente desconectar a VPN e testar novamente"
else
    print_success "Nenhuma VPN ativa detectada"
fi
echo ""

# 6. Testar conexão via Python (fallback)
print_info "6️⃣  Testando conexão via Python..."
python3 << PYTHON_SCRIPT
import socket
import sys

try:
    sock = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
    sock.settimeout(5)
    result = sock.connect_ex(('$DB_HOST', $DB_PORT))
    sock.close()
    
    if result == 0:
        print("✅ Socket Python conseguiu conectar!")
        sys.exit(0)
    else:
        print(f"❌ Socket Python não conseguiu conectar (código: {result})")
        sys.exit(1)
except Exception as e:
    print(f"❌ Erro no teste Python: {e}")
    sys.exit(1)
PYTHON_SCRIPT

PYTHON_RESULT=$?
if [ $PYTHON_RESULT -eq 0 ]; then
    print_success "Teste Python passou!"
else
    print_error "Teste Python falhou"
fi
echo ""

# 7. Resumo e próximos passos
echo "════════════════════════════════════════════════════════════"
print_info "📋 DIAGNÓSTICO COMPLETO:"
echo ""

if timeout 5 bash -c "echo > /dev/tcp/$DB_HOST/$DB_PORT" 2>/dev/null || [ $PYTHON_RESULT -eq 0 ]; then
    print_success "✅ CONEXÃO FUNCIONANDO!"
    print_info "Você pode prosseguir com: ./scripts/dev/iniciar-dev-local.sh"
else
    print_error "❌ CONEXÃO AINDA NÃO FUNCIONA"
    echo ""
    print_info "🔧 PRÓXIMOS PASSOS:"
    echo ""
    echo "1. Verificar no SERVIDOR (82.25.92.217):"
    echo "   - PostgreSQL está escutando em todas as interfaces?"
    echo "   - Firewall do servidor permite conexões de entrada na porta 5432?"
    echo "   - pg_hba.conf permite conexões do seu IP?"
    echo ""
    echo "2. Verificar sua REDE:"
    echo "   - Está em uma rede corporativa com firewall?"
    echo "   - Precisa de VPN para acessar o servidor?"
    echo "   - ISP bloqueia porta 5432?"
    echo ""
    echo "3. Testar de outro local:"
    echo "   - Tente de outra rede (casa, escritório, mobile hotspot)"
    echo "   - Isso ajuda a identificar se é problema de rede local"
    echo ""
    echo "4. Usar túnel SSH (alternativa):"
    echo "   - Se tiver acesso SSH ao servidor, pode criar túnel:"
    echo "   ssh -L 5432:localhost:5432 user@82.25.92.217"
    echo "   - Depois usar localhost:5432 no DATABASE_URL"
    echo ""
    print_info "Execute no servidor para verificar configuração:"
    echo "  ./scripts/diagnostico/verificar-postgresql-servidor.sh"
fi
echo ""

