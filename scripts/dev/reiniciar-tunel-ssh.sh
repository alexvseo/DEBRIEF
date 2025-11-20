#!/bin/bash

################################################################################
# Script para reiniciar o túnel SSH (força parada e reinicia)
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

REMOTE_USER="root"
REMOTE_HOST="82.25.92.217"
REMOTE_SSH_PORT="22"
LOCAL_DB_PORT="5432"
REMOTE_DB_PORT="5432"

echo "🔄 Reiniciando Túnel SSH para o Banco de Dados Remoto..."
echo ""

# 1. Parar túneis existentes
print_info "1️⃣  Parando túneis SSH existentes..."
pkill -f "ssh.*${LOCAL_DB_PORT}.*${REMOTE_HOST}" 2>/dev/null || true
sleep 2

# Verificar se porta está livre
if lsof -i :${LOCAL_DB_PORT} &> /dev/null; then
    print_warning "Porta ${LOCAL_DB_PORT} ainda está em uso. Tentando forçar liberação..."
    lsof -ti :${LOCAL_DB_PORT} | xargs kill -9 2>/dev/null || true
    sleep 2
fi

if lsof -i :${LOCAL_DB_PORT} &> /dev/null; then
    print_error "Não foi possível liberar a porta ${LOCAL_DB_PORT}."
    print_info "Execute manualmente: lsof -i :${LOCAL_DB_PORT}"
    exit 1
fi

print_success "Porta ${LOCAL_DB_PORT} liberada."

# 2. Verificar se autossh está disponível
print_info "2️⃣  Verificando autossh..."
if command -v autossh &> /dev/null; then
    USE_AUTOSSH=true
    print_success "autossh encontrado (recomendado para reconexão automática)."
else
    USE_AUTOSSH=false
    print_warning "autossh NÃO encontrado. Usando ssh normal."
fi
echo ""

# 3. Iniciar novo túnel
print_info "3️⃣  Iniciando novo túnel SSH..."
print_info "  - Você será solicitado a digitar a senha do usuário '${REMOTE_USER}' no servidor '${REMOTE_HOST}'."
print_info "  - O túnel será executado em segundo plano."
echo ""

SSH_COMMAND="-N -L ${LOCAL_DB_PORT}:localhost:${REMOTE_DB_PORT} ${REMOTE_USER}@${REMOTE_HOST} -p ${REMOTE_SSH_PORT} -o ServerAliveInterval=60 -o ServerAliveCountMax=3 -o StrictHostKeyChecking=no"

if [ "$USE_AUTOSSH" = true ]; then
    autossh -M 0 -f "${SSH_COMMAND}"
    if [ $? -eq 0 ]; then
        print_success "Túnel SSH iniciado com autossh em segundo plano."
    else
        print_error "Falha ao iniciar túnel SSH com autossh."
        exit 1
    fi
else
    ssh -f "${SSH_COMMAND}"
    if [ $? -eq 0 ]; then
        print_success "Túnel SSH iniciado com ssh em segundo plano."
        print_warning "  - Este túnel NÃO irá reconectar automaticamente se a conexão cair."
    else
        print_error "Falha ao iniciar túnel SSH."
        exit 1
    fi
fi

sleep 2

# 4. Verificar se túnel está ativo
print_info "4️⃣  Verificando se túnel está ativo..."
if lsof -i :${LOCAL_DB_PORT} | grep -q "ssh"; then
    print_success "✅ Túnel SSH ativo em localhost:${LOCAL_DB_PORT}"
    PID=$(lsof -ti :${LOCAL_DB_PORT} | head -1)
    print_info "  - PID: ${PID}"
else
    print_error "Túnel SSH não está ativo. Verifique os logs acima."
    exit 1
fi
echo ""

print_success "✅ ✅ Túnel SSH reiniciado com sucesso!"
print_info "Agora, o backend local pode se conectar ao banco de dados remoto usando 'localhost:${LOCAL_DB_PORT}'."
print_info "Para parar o túnel, execute: ./scripts/dev/parar-tunel-ssh.sh"
print_info "Para iniciar o ambiente de desenvolvimento local, execute: ./scripts/dev/iniciar-dev-local.sh"

