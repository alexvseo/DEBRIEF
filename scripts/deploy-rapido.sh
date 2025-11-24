#!/bin/bash

# ========================================
# DEPLOY RÁPIDO (sem rebuild)
# Use quando fizer mudanças apenas em código
# ========================================

set -e

echo "🚀 Deploy Rápido - DeBrief"
echo ""

# Push para GitHub
echo "📤 Enviando para GitHub..."
git add .
read -p "📝 Mensagem do commit: " msg
git commit -m "$msg"
git push origin main

echo ""
echo "🔄 Atualizando servidor..."

# Deploy no servidor (apenas restart, sem rebuild)
ssh debrief << 'ENDSSH'
    cd /var/www/debrief
    git fetch origin
    git reset --hard origin/main
    docker-compose restart backend frontend
    echo "✅ Serviços reiniciados!"
    sleep 5
    docker-compose ps | grep -E 'debrief-backend|debrief-frontend'
ENDSSH

echo ""
echo "✅ Deploy concluído!"
echo "🌐 Teste em: https://debrief.interce.com.br"

