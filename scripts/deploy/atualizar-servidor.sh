#!/bin/bash

################################################################################
# Script para atualizar o servidor com as últimas mudanças do Git
# 
# Uso:
#   ./atualizar-servidor.sh
#
# Requisitos:
#   - Acesso SSH ao servidor (82.25.92.217)
#   - Git configurado no servidor
#   - Docker e docker-compose instalados
################################################################################

set -e  # Parar em caso de erro

# Cores para output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configurações
SERVER_HOST="82.25.92.217"
SERVER_USER="root"  # Ajustar se necessário
SERVER_PATH="/root/debrief"  # Ajustar se necessário

# Funções auxiliares
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

# Verificar se está no diretório correto
if [ ! -f "docker-compose.yml" ]; then
    print_error "Este script deve ser executado na raiz do projeto"
    exit 1
fi

print_info "🚀 Iniciando atualização do servidor..."
echo ""

# 1. Fazer pull no servidor
print_info "1️⃣  Conectando ao servidor e fazendo git pull..."
ssh ${SERVER_USER}@${SERVER_HOST} << 'ENDSSH'
    cd /root/debrief || exit 1
    
    # Verificar se há mudanças locais
    if [ -n "$(git status --porcelain 2>/dev/null)" ]; then
        echo "⚠️  Há mudanças locais no servidor"
        echo "Descartando mudanças locais..."
        git checkout -- . 2>/dev/null || true
        git reset --hard HEAD 2>/dev/null || true
    fi
    
    # Fazer pull
    echo "Fazendo git pull..."
    git pull origin main 2>&1 || git pull origin master 2>&1
    
    if [ $? -eq 0 ]; then
        echo "✅ Git pull realizado com sucesso"
    else
        echo "❌ Erro ao fazer git pull"
        exit 1
    fi
ENDSSH

if [ $? -ne 0 ]; then
    print_error "Falha ao fazer git pull no servidor"
    exit 1
fi

print_success "Git pull realizado com sucesso"
echo ""

# 2. Rebuild e restart dos containers
print_info "2️⃣  Reconstruindo e reiniciando containers Docker..."
ssh ${SERVER_USER}@${SERVER_HOST} << 'ENDSSH'
    cd /root/debrief || exit 1
    
    echo "Parando containers..."
    docker-compose down 2>/dev/null || true
    
    echo "Reconstruindo imagens..."
    docker-compose build --no-cache 2>&1
    
    if [ $? -ne 0 ]; then
        echo "❌ Erro ao reconstruir imagens"
        exit 1
    fi
    
    echo "Iniciando containers..."
    docker-compose up -d 2>&1
    
    if [ $? -ne 0 ]; then
        echo "❌ Erro ao iniciar containers"
        exit 1
    fi
    
    echo "✅ Containers iniciados"
ENDSSH

if [ $? -ne 0 ]; then
    print_error "Falha ao reconstruir/restartar containers"
    exit 1
fi

print_success "Containers reconstruídos e reiniciados"
echo ""

# 3. Verificar status dos containers
print_info "3️⃣  Verificando status dos containers..."
ssh ${SERVER_USER}@${SERVER_HOST} << 'ENDSSH'
    cd /root/debrief || exit 1
    
    echo ""
    echo "Status dos containers:"
    docker-compose ps
    
    echo ""
    echo "Verificando saúde dos containers..."
    sleep 5
    
    # Verificar backend
    if docker-compose exec -T backend curl -f http://localhost:8000/api/health > /dev/null 2>&1; then
        echo "✅ Backend está saudável"
    else
        echo "⚠️  Backend pode estar com problemas"
    fi
    
    # Verificar frontend
    if docker-compose exec -T frontend curl -f http://localhost:80 > /dev/null 2>&1; then
        echo "✅ Frontend está saudável"
    else
        echo "⚠️  Frontend pode estar com problemas"
    fi
ENDSSH

print_success "Verificação concluída"
echo ""

# 4. Mostrar logs recentes
print_info "4️⃣  Últimos logs do backend (últimas 20 linhas):"
ssh ${SERVER_USER}@${SERVER_HOST} << 'ENDSSH'
    cd /root/debrief || exit 1
    docker-compose logs --tail=20 backend
ENDSSH

echo ""
print_success "🎉 Atualização do servidor concluída!"
print_info "Acesse: http://${SERVER_HOST}:2022"
echo ""

