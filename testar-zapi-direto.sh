#!/bin/bash

echo "🧪 TESTE DIRETO Z-API"
echo "===================="
echo ""

INSTANCE_ID="3EABC3821EF52114B8836EDB289F0F12"
TOKEN="F9BFDFA1F0A75E79536CE12D"
BASE_URL="https://api.z-api.io/instances/$INSTANCE_ID/token/$TOKEN"
PHONE="5585991042626"

echo "1️⃣ Verificando status da instância Z-API..."
echo ""

STATUS=$(curl -s -H "Client-Token: $TOKEN" "$BASE_URL/status")
echo "📊 Status: $STATUS"
echo ""

if echo "$STATUS" | grep -q '"connected":true'; then
    echo "✅ Z-API está conectado!"
else
    echo "⚠️  Z-API não está conectado. Resultado:"
    echo "$STATUS"
fi

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

echo "2️⃣ Enviando mensagem de teste..."
echo "Para: $PHONE"
echo ""

RESULTADO=$(curl -s -X POST "$BASE_URL/send-text" \
  -H "Content-Type: application/json" \
  -H "Client-Token: $TOKEN" \
  -d "{
    \"phone\": \"$PHONE\",
    \"message\": \"✅ Teste DeBrief Z-API - $(date +%H:%M:%S)\\n\\nIntegração funcionando!\"
  }")

echo "📬 Resultado: $RESULTADO"
echo ""

if echo "$RESULTADO" | grep -q '"messageId"'; then
    MESSAGE_ID=$(echo "$RESULTADO" | grep -o '"messageId":"[^"]*' | cut -d'"' -f4)
    echo "🎉 MENSAGEM ENVIADA COM SUCESSO!"
    echo "📝 Message ID: $MESSAGE_ID"
else
    echo "❌ FALHA NO ENVIO"
    echo "Verifique se:"
    echo "  • Token está correto"
    echo "  • Instância está ativa"
    echo "  • Número está no formato correto"
fi

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

