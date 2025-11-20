#!/bin/bash

# Script para limpar cache do frontend e forçar rebuild

echo "🧹 Limpando cache do frontend..."
echo ""

echo "1️⃣  Parando containers..."
docker-compose stop frontend
echo ""

echo "2️⃣  Removendo container frontend..."
docker-compose rm -f frontend
echo ""

echo "3️⃣  Removendo imagem do frontend..."
docker rmi debrief-frontend:latest 2>/dev/null || echo "   (Imagem não encontrada ou já removida)"
echo ""

echo "4️⃣  Limpando cache do Docker BuildKit..."
docker builder prune -f
echo ""

echo "5️⃣  Reconstruindo frontend (sem cache)..."
docker-compose build --no-cache frontend
echo ""

echo "6️⃣  Iniciando frontend..."
docker-compose up -d frontend
echo ""

echo "7️⃣  Aguardando frontend ficar healthy..."
sleep 10

echo ""
echo "8️⃣  Verificando status..."
docker-compose ps frontend
echo ""

echo "✅ Cache limpo e frontend reconstruído!"
echo ""
echo "💡 Agora:"
echo "   1. Limpe o cache do navegador (Ctrl+Shift+R ou Cmd+Shift+R)"
echo "   2. Ou abra em modo anônimo/privado"
echo "   3. Recarregue a página"

