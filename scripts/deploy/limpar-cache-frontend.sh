#!/bin/bash

echo "🧹 Limpando cache e forçando rebuild do frontend..."
echo ""

# 1. Parar e remover o container frontend
echo "1️⃣  Parando e removendo container 'debrief-frontend'..."
docker-compose stop frontend
docker-compose rm -f frontend
echo "   ✅ Container removido."
echo ""

# 2. Remover a imagem antiga do frontend
echo "2️⃣  Removendo imagem 'debrief-frontend:latest' (se existir)..."
docker rmi debrief-frontend:latest 2>/dev/null || true
echo "   ✅ Imagem removida (ou não existia)."
echo ""

# 3. Reconstruir a imagem do frontend sem cache
echo "3️⃣  Reconstruindo imagem 'debrief-frontend' sem cache..."
docker-compose build --no-cache frontend
echo "   ✅ Imagem reconstruída."
echo ""

# 4. Iniciar o container frontend
echo "4️⃣  Iniciando container 'debrief-frontend'..."
docker-compose up -d frontend
echo "   ✅ Container iniciado."
echo ""

# 5. Verificar o status do container
echo "5️⃣  Verificando status do container 'debrief-frontend'..."
docker-compose ps frontend
echo ""

echo "✅ Limpeza de cache e rebuild do frontend concluídos."
echo "   Por favor, limpe o cache do seu navegador (Ctrl+Shift+R ou Cmd+Shift+R) e recarregue a página."
