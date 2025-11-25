#!/bin/bash

echo "🧪 TESTE RÁPIDO - WhatsApp Evolution API"
echo "========================================"
echo ""

SERVER="82.25.92.217"
API_KEY="debrief-wpp-58a2b7dda7da9474958e2a853062d5d5"
INSTANCE="debrief"

echo "1️⃣ Verificando status da instância..."
STATUS=$(ssh root@$SERVER "curl -s -H 'apikey: $API_KEY' http://localhost:21465/instance/connectionState/$INSTANCE")
echo "Status: $STATUS"
echo ""

echo "2️⃣ Testando envio de mensagem..."
RESULTADO=$(ssh root@$SERVER "curl -s -X POST http://localhost:21465/message/sendText/$INSTANCE \
  -H 'Content-Type: application/json' \
  -H 'apikey: $API_KEY' \
  -d '{
    \"number\": \"5585991042626\",
    \"textMessage\": {
      \"text\": \"✅ Teste DeBrief - $(date +%H:%M:%S)\"
    }
  }'")

echo "Resultado: $RESULTADO"
echo ""

if echo "$RESULTADO" | grep -q '"key"'; then
    echo "✅ MENSAGEM ENVIADA COM SUCESSO!"
else
    echo "❌ FALHA NO ENVIO"
fi

