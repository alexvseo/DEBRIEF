#!/bin/bash
# Script para limpar cache do SQLAlchemy e reiniciar backend completamente

echo "🔧 Limpando cache e reiniciando backend completamente..."
echo ""

echo "1️⃣  Parando containers..."
docker-compose stop backend frontend
echo ""

echo "2️⃣  Removendo container backend (força recriação)..."
docker-compose rm -f backend
echo ""

echo "3️⃣  Reconstruindo e iniciando containers..."
docker-compose up -d --build backend
echo ""

echo "4️⃣  Aguardando inicialização (30 segundos)..."
sleep 30
echo ""

echo "5️⃣  Verificando saúde do backend..."
for i in {1..10}; do
    if curl -s http://localhost:8000/health > /dev/null 2>&1; then
        echo "   ✅ Backend está respondendo"
        break
    else
        echo "   ⏳ Aguardando... ($i/10)"
        sleep 3
    fi
done
echo ""

echo "6️⃣  Verificando logs de erro..."
ERRORS=$(docker-compose logs backend | grep -E "LookupError|InvalidTextRepresentation" | tail -5)
if [ -z "$ERRORS" ]; then
    echo "   ✅ Nenhum erro de enum encontrado nos logs recentes"
else
    echo "   ⚠️  Ainda há erros:"
    echo "$ERRORS"
fi
echo ""

echo "✅ Processo concluído!"
echo ""
echo "📋 Próximos passos:"
echo "   1. Testar endpoint de secretarias"
echo "   2. Verificar frontend em http://82.25.92.217:2022/configuracoes"

