#!/bin/bash

# Script para corrigir duplicação de /api no frontend
# O problema: frontend está fazendo requisições para /api/api/... em vez de /api/...

echo "🔧 Corrigindo duplicação de /api no frontend"
echo ""

echo "1️⃣  Verificando build do frontend..."
echo ""
if [ -d "frontend/dist" ]; then
    echo "   ✅ Diretório dist existe"
    # Verificar se há referências a /api/api no build
    if grep -r "/api/api" frontend/dist 2>/dev/null | head -5; then
        echo "   ⚠️  Encontradas referências a /api/api no build"
    else
        echo "   ✅ Nenhuma referência a /api/api encontrada no build"
    fi
else
    echo "   ⚠️  Diretório dist não existe (frontend não foi buildado)"
fi
echo ""

echo "2️⃣  Verificando código fonte do frontend..."
echo ""
# Verificar se há chamadas com /api/ manualmente
if grep -r "api\.\(get\|post\|put\|delete\|patch\)(['\"]/api" frontend/src 2>/dev/null | head -10; then
    echo "   ⚠️  Encontradas chamadas com /api/ manualmente no código"
    echo "   💡 Essas chamadas devem usar caminho relativo (sem /api/)"
else
    echo "   ✅ Nenhuma chamada com /api/ manual encontrada"
fi
echo ""

echo "3️⃣  Rebuild do frontend com configuração correta..."
echo ""
cd frontend || exit 1

# Verificar se VITE_API_URL está correto
if grep -q "VITE_API_URL=/api" ../docker-compose.yml; then
    echo "   ✅ VITE_API_URL está configurado como /api no docker-compose.yml"
else
    echo "   ⚠️  VITE_API_URL não encontrado ou incorreto"
fi

echo ""
echo "4️⃣  Rebuild do container frontend..."
echo ""
cd .. || exit 1
docker-compose build --no-cache frontend
echo ""

echo "5️⃣  Reiniciar frontend..."
echo ""
docker-compose restart frontend
echo ""

echo "6️⃣  Aguardar frontend iniciar (10 segundos)..."
echo ""
sleep 10

echo "7️⃣  Verificar logs do frontend..."
echo ""
docker-compose logs frontend | tail -20
echo ""

echo "✅ Correção aplicada"
echo ""
echo "💡 Se o problema persistir, verifique:"
echo "   1. Se o código do frontend está usando caminhos relativos (sem /api/)"
echo "   2. Se o build está usando a versão mais recente do código"
echo "   3. Se há cache do navegador (limpar cache ou usar modo anônimo)"

