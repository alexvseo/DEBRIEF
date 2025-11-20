#!/bin/bash

################################################################################
# Script para criar túnel SSH para acessar banco remoto
# Útil quando firewall bloqueia conexão direta
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

echo "🔗 Configurando túnel SSH para banco de dados..."
echo ""

# Configurações
SSH_HOST="82.25.92.217"
SSH_USER="${SSH_USER:-root}"
LOCAL_PORT="5432"
REMOTE_HOST="localhost"
REMOTE_PORT="5432"
TUNEL_PID_FILE="/tmp/debrief-ssh-tunnel.pid"

# Verificar se túnel já está rodando
if [ -f "$TUNEL_PID_FILE" ]; then
    OLD_PID=$(cat "$TUNEL_PID_FILE")
    if ps -p "$OLD_PID" > /dev/null 2>&1; then
        print_warning "Túnel SSH já está rodando (PID: $OLD_PID)"
        print_info "Deseja parar e recriar? (s/N)"
        read -r resposta
        if [ "$resposta" = "s" ] || [ "$resposta" = "S" ]; then
            kill "$OLD_PID" 2>/dev/null || true
            rm -f "$TUNEL_PID_FILE"
            print_success "Túnel anterior parado"
        else
            print_info "Mantendo túnel existente"
            exit 0
        fi
    else
        rm -f "$TUNEL_PID_FILE"
    fi
fi

# Verificar se porta local está em uso
if lsof -Pi :$LOCAL_PORT -sTCP:LISTEN -t >/dev/null 2>&1; then
    print_warning "Porta $LOCAL_PORT já está em uso"
    print_info "Deseja parar o processo? (s/N)"
    read -r resposta
    if [ "$resposta" = "s" ] || [ "$resposta" = "S" ]; then
        PID=$(lsof -ti:$LOCAL_PORT)
        kill -9 $PID 2>/dev/null || true
        print_success "Processo na porta $LOCAL_PORT finalizado"
    else
        print_error "Não é possível criar túnel. Porta em uso."
        exit 1
    fi
fi

# Verificar se autossh está instalado (recomendado)
if command -v autossh &> /dev/null; then
    USE_AUTOSSH=true
    print_success "autossh encontrado (reconexão automática)"
else
    USE_AUTOSSH=false
    print_warning "autossh não encontrado. Usando ssh normal."
    print_info "Para reconexão automática, instale: brew install autossh"
fi
echo ""

# Criar túnel
print_info "Criando túnel SSH..."
print_info "  Local: localhost:$LOCAL_PORT"
print_info "  Remoto: $SSH_HOST:$REMOTE_PORT"
print_info "  Usuário: $SSH_USER"
echo ""

if [ "$USE_AUTOSSH" = true ]; then
    print_info "Iniciando túnel com autossh (reconexão automática)..."
    autossh -M 20000 \
        -f -N \
        -L $LOCAL_PORT:$REMOTE_HOST:$REMOTE_PORT \
        -o "ServerAliveInterval=60" \
        -o "ServerAliveCountMax=3" \
        -o "StrictHostKeyChecking=no" \
        "$SSH_USER@$SSH_HOST"
    
    # Encontrar PID do autossh
    sleep 2
    TUNEL_PID=$(ps aux | grep "autossh.*$LOCAL_PORT" | grep -v grep | awk '{print $2}' | head -n1)
else
    print_info "Iniciando túnel com ssh..."
    ssh -f -N \
        -L $LOCAL_PORT:$REMOTE_HOST:$REMOTE_PORT \
        -o "ServerAliveInterval=60" \
        -o "ServerAliveCountMax=3" \
        -o "StrictHostKeyChecking=no" \
        "$SSH_USER@$SSH_HOST"
    
    # Encontrar PID do ssh
    sleep 2
    TUNEL_PID=$(ps aux | grep "ssh.*$LOCAL_PORT" | grep -v grep | awk '{print $2}' | head -n1)
fi

if [ -n "$TUNEL_PID" ]; then
    echo "$TUNEL_PID" > "$TUNEL_PID_FILE"
    print_success "Túnel SSH criado com sucesso! (PID: $TUNEL_PID)"
else
    print_error "Não foi possível criar túnel SSH"
    print_info "Verifique:"
    echo "  - Acesso SSH ao servidor ($SSH_USER@$SSH_HOST)"
    echo "  - Credenciais SSH corretas"
    echo "  - Porta 22 (SSH) está acessível"
    exit 1
fi

# Aguardar túnel estabilizar
sleep 2

# Testar conexão através do túnel
print_info "Testando conexão através do túnel..."
if timeout 5 bash -c "echo > /dev/tcp/localhost/$LOCAL_PORT" 2>/dev/null; then
    print_success "Túnel está funcionando!"
    
    # Testar conexão com PostgreSQL
    if command -v psql &> /dev/null; then
        export PGPASSWORD="Mslestrategia.2025@"
        if timeout 5 psql -h localhost -p $LOCAL_PORT -U postgres -d dbrief -c "SELECT 1;" -t > /dev/null 2>&1; then
            print_success "Conexão com PostgreSQL através do túnel funcionou!"
        else
            print_warning "Túnel criado, mas conexão PostgreSQL falhou"
            print_info "Verifique credenciais do banco"
        fi
        unset PGPASSWORD
    fi
else
    print_warning "Túnel criado, mas porta local não está respondendo"
    print_info "Verifique logs: ps aux | grep ssh"
fi
echo ""

# Instruções
print_success "🎉 Túnel SSH configurado!"
echo ""
print_info "📋 PRÓXIMOS PASSOS:"
echo ""
echo "1. Atualize backend/.env.dev:"
echo "   DATABASE_URL=postgresql://postgres:Mslestrategia.2025%40@localhost:5432/dbrief"
echo ""
echo "2. Mantenha este túnel rodando enquanto desenvolve"
echo ""
echo "3. Para parar o túnel:"
echo "   ./scripts/dev/parar-tunel-ssh.sh"
echo ""
echo "4. Para verificar status:"
echo "   ps aux | grep 'ssh.*5432'"
echo ""

