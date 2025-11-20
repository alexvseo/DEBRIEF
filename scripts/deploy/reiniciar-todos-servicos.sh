#!/bin/bash
# Script para reiniciar todos os serviços e corrigir erro 502

echo "🔧 Reiniciando todos os serviços..."
echo ""

echo "1️⃣  Parando todos os containers..."
docker-compose stop
echo ""

echo "2️⃣  Iniciando todos os containers..."
docker-compose up -d
echo ""

echo "3️⃣  Aguardando inicialização (30 segundos)..."
sleep 30
echo ""

echo "4️⃣  Verificando status dos containers..."
docker-compose ps
echo ""

echo "5️⃣  Verificando se backend está respondendo..."
for i in {1..10}; do
    if curl -s http://localhost:8000/health > /dev/null 2>&1; then
        echo "   ✅ Backend está respondendo"
        break
    else
        echo "   ⏳ Aguardando backend... ($i/10)"
        sleep 3
    fi
done
echo ""

echo "6️⃣  Verificando se frontend está respondendo..."
for i in {1..10}; do
    if curl -s http://localhost:80 > /dev/null 2>&1; then
        echo "   ✅ Frontend está respondendo"
        break
    else
        echo "   ⏳ Aguardando frontend... ($i/10)"
        sleep 3
    fi
done
echo ""

echo "7️⃣  Verificando se Caddy está respondendo..."
for i in {1..10}; do
    RESPONSE=$(curl -s -o /dev/null -w "%{http_code}" http://localhost:2022/ 2>&1)
    if [ "$RESPONSE" = "200" ] || [ "$RESPONSE" = "302" ] || [ "$RESPONSE" = "304" ]; then
        echo "   ✅ Caddy está respondendo (HTTP $RESPONSE)"
        break
    else
        echo "   ⏳ Aguardando Caddy... ($i/10) - HTTP $RESPONSE"
        sleep 3
    fi
done
echo ""

echo "8️⃣  Verificando logs do Caddy..."
docker-compose logs caddy | tail -20
echo ""

echo "✅ Processo concluído!"
echo ""
echo "📋 Se ainda houver erro 502:"
echo "   1. Execute: ./scripts/deploy/diagnosticar-502.sh"
echo "   2. Verifique logs: docker-compose logs caddy | tail -50"
echo "   3. Verifique se portas estão abertas: netstat -tlnp | grep -E ':(2022|8000|80)'"

