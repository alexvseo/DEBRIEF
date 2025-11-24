#!/bin/bash

# Script para Deploy da Correção do Enum de Usuário

echo "=================================================="
echo "🚀 DEPLOY DA CORREÇÃO - ENUM TIPO USUÁRIO"
echo "=================================================="
echo ""

echo "1️⃣ Fazendo commit das alterações"
echo "=================================================="
git add backend/app/models/user.py
git commit -m "fix: Corrige serialização do campo tipo de usuário (TipoUsuario enum)"
echo ""

echo "2️⃣ Enviando para o repositório"
echo "=================================================="
git push origin main
echo ""

echo "3️⃣ Conectando ao servidor e fazendo deploy"
echo "=================================================="
SERVER="root@82.25.92.217"

ssh $SERVER << 'ENDSSH'

cd /var/www/debrief

echo "📥 Fazendo pull das alterações..."
git pull origin main

echo ""
echo "🔨 Reconstruindo imagem do backend..."
docker-compose build backend

echo ""
echo "🔄 Reiniciando backend..."
docker-compose up -d backend

echo ""
echo "⏳ Aguardando 12 segundos para o backend iniciar..."
sleep 12

echo ""
echo "📋 Verificando logs..."
docker logs debrief-backend --tail 20

echo ""
echo "🧪 Testando endpoint de health..."
curl -s http://localhost:2023/health
echo ""

ENDSSH

echo ""
echo "=================================================="
echo "✅ DEPLOY CONCLUÍDO!"
echo "=================================================="
echo ""
echo "Teste o dashboard agora: https://debrief.interce.com.br/dashboard"

