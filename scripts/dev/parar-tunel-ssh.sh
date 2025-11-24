#!/bin/bash

################################################################################
# Script para parar túnel SSH
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

TUNEL_PID_FILE="/tmp/debrief-ssh-tunnel.pid"
LOCAL_PORT="5432"

echo "🛑 Parando túnel SSH..."
echo ""

# Parar via PID file
if [ -f "$TUNEL_PID_FILE" ]; then
    PID=$(cat "$TUNEL_PID_FILE")
    if ps -p "$PID" > /dev/null 2>&1; then
        kill "$PID" 2>/dev/null || true
        sleep 1
        if ! ps -p "$PID" > /dev/null 2>&1; then
            print_success "Túnel parado (PID: $PID)"
        else
            kill -9 "$PID" 2>/dev/null || true
            print_success "Túnel forçado a parar (PID: $PID)"
        fi
        rm -f "$TUNEL_PID_FILE"
    else
        print_warning "PID no arquivo não está mais ativo"
        rm -f "$TUNEL_PID_FILE"
    fi
fi

# Parar processos SSH na porta
PIDS=$(lsof -ti:$LOCAL_PORT 2>/dev/null || echo "")
if [ -n "$PIDS" ]; then
    for PID in $PIDS; do
        if ps -p "$PID" > /dev/null 2>&1; then
            # Verificar se é túnel SSH
            CMD=$(ps -p "$PID" -o command= 2>/dev/null || echo "")
            if echo "$CMD" | grep -q "ssh.*5432\|autossh.*5432"; then
                kill "$PID" 2>/dev/null || true
                print_success "Processo SSH parado (PID: $PID)"
            fi
        fi
    done
else
    print_info "Nenhum processo SSH encontrado na porta $LOCAL_PORT"
fi

echo ""
print_success "✅ Túnel SSH parado"

