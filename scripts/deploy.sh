#!/bin/bash

# ========================================
# SCRIPT DE DEPLOY AUTOMATIZADO - DEBRIEF
# ========================================

set -e  # Parar em caso de erro

echo ""
echo "🚀 =========================================="
echo "   DEPLOY DEBRIEF - VPS HOSTINGER"
echo "=========================================="
echo ""

# Cores para output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Função para log
log_info() {
    echo -e "${BLUE}ℹ️  $1${NC}"
}

log_success() {
    echo -e "${GREEN}✅ $1${NC}"
}

log_warning() {
    echo -e "${YELLOW}⚠️  $1${NC}"
}

log_error() {
    echo -e "${RED}❌ $1${NC}"
}

# Verificar se há mudanças não comitadas
if [[ -n $(git status -s) ]]; then
    log_warning "Há mudanças não comitadas no repositório!"
    echo ""
    git status -s
    echo ""
    read -p "Deseja fazer commit dessas mudanças? (s/N) " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Ss]$ ]]; then
        read -p "📝 Mensagem do commit: " commit_msg
        git add .
        git commit -m "$commit_msg"
        log_success "Commit realizado!"
    else
        log_error "Deploy cancelado. Faça commit das mudanças primeiro."
        exit 1
    fi
fi

# Push para GitHub
log_info "Enviando código para GitHub..."
git push origin main
log_success "Código enviado para GitHub!"

echo ""
log_info "Conectando ao VPS..."

# Deploy no servidor
ssh debrief << 'ENDSSH'
    set -e
    
    echo ""
    echo "📦 Atualizando código no servidor..."
    cd /var/www/debrief
    
    # Pull das últimas alterações
    git fetch origin
    git reset --hard origin/main
    echo "✅ Código atualizado!"
    
    echo ""
    echo "🐳 Reconstruindo containers..."
    
    # Rebuild apenas se houve mudanças no código
    docker-compose build --no-cache backend frontend
    
    echo ""
    echo "🔄 Reiniciando serviços..."
    docker-compose up -d --force-recreate backend frontend
    
    echo ""
    echo "⏳ Aguardando containers iniciarem..."
    sleep 10
    
    echo ""
    echo "📊 Status dos containers:"
    docker-compose ps
    
    echo ""
    echo "📝 Logs recentes do backend:"
    docker-compose logs --tail=20 backend
    
ENDSSH

log_success "Deploy concluído!"

echo ""
echo "=========================================="
echo "🎉 DEPLOY FINALIZADO COM SUCESSO!"
echo "=========================================="
echo ""
echo "🌐 Teste em: https://debrief.interce.com.br"
echo "📊 API: https://debrief.interce.com.br/api/docs"
echo ""
echo "Para ver logs em tempo real:"
echo "  ssh debrief 'cd /var/www/debrief && docker-compose logs -f backend'"
echo ""

