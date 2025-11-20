#!/bin/bash
# Script para diagnosticar erro 502

echo "🔍 Diagnosticando erro 502..."
echo ""

echo "1️⃣  Verificando status dos containers..."
docker-compose ps
echo ""

echo "2️⃣  Verificando se backend está respondendo..."
if curl -s http://localhost:8000/health > /dev/null 2>&1; then
    echo "   ✅ Backend está respondendo na porta 8000"
else
    echo "   ❌ Backend NÃO está respondendo na porta 8000"
fi
echo ""

echo "3️⃣  Verificando se frontend está respondendo..."
if curl -s http://localhost:80 > /dev/null 2>&1; then
    echo "   ✅ Frontend está respondendo na porta 80"
else
    echo "   ❌ Frontend NÃO está respondendo na porta 80"
fi
echo ""

echo "4️⃣  Verificando se Caddy está rodando..."
if docker-compose ps | grep -q "caddy.*Up"; then
    echo "   ✅ Caddy está rodando"
else
    echo "   ❌ Caddy NÃO está rodando"
fi
echo ""

echo "5️⃣  Verificando logs do Caddy..."
docker-compose logs caddy | tail -20
echo ""

echo "6️⃣  Verificando logs do backend..."
docker-compose logs backend | tail -10
echo ""

echo "7️⃣  Verificando logs do frontend..."
docker-compose logs frontend | tail -10
echo ""

echo "8️⃣  Testando acesso via Caddy (porta 2022)..."
RESPONSE=$(curl -s -o /dev/null -w "%{http_code}" http://localhost:2022/ 2>&1)
if [ "$RESPONSE" = "200" ] || [ "$RESPONSE" = "302" ] || [ "$RESPONSE" = "304" ]; then
    echo "   ✅ Caddy está respondendo (HTTP $RESPONSE)"
else
    echo "   ❌ Caddy retornou HTTP $RESPONSE"
fi
echo ""

echo "9️⃣  Verificando portas abertas..."
netstat -tlnp | grep -E ":(2022|8000|80)" || ss -tlnp | grep -E ":(2022|8000|80)"
echo ""

echo "✅ Diagnóstico concluído!"

