#!/bin/bash

# 🔄 Reconectar WhatsApp Z-API
# Gera QR Code para escanear

echo ""
echo "╔══════════════════════════════════════════════════════════════╗"
echo "║                                                              ║"
echo "║  🔄 RECONECTANDO WHATSAPP - Z-API                            ║"
echo "║                                                              ║"
echo "╚══════════════════════════════════════════════════════════════╝"
echo ""

INSTANCE_ID="3EABC3821EF52114B8836EDB289F0F12"
TOKEN="F9BFDFA1F0A75E79536CE12D"
CLIENT_TOKEN="F47cfa53858ee4869bf3e027187aa6742S"
BASE_URL="https://api.z-api.io/instances/$INSTANCE_ID/token/$TOKEN"

echo "1️⃣ Verificando status atual..."
STATUS=$(curl -s -X GET "$BASE_URL/status" \
  -H "Client-Token: $CLIENT_TOKEN" \
  -H "Content-Type: application/json")

echo "$STATUS" | python3 -m json.tool
echo ""

CONNECTED=$(echo "$STATUS" | python3 -c "import sys, json; print(json.load(sys.stdin).get('connected', False))" 2>/dev/null)

if [ "$CONNECTED" = "True" ]; then
    echo "✅ WhatsApp já está conectado!"
    exit 0
fi

echo "⚠️  WhatsApp está desconectado. Gerando QR Code..."
echo ""

echo "2️⃣ Obtendo QR Code da Z-API..."
QR_RESPONSE=$(curl -s -X GET "$BASE_URL/qr-code" \
  -H "Client-Token: $CLIENT_TOKEN" \
  -H "Content-Type: application/json")

QR_VALUE=$(echo "$QR_RESPONSE" | python3 -c "import sys, json; print(json.load(sys.stdin).get('value', ''))" 2>/dev/null)

if [ -z "$QR_VALUE" ] || [ "$QR_VALUE" = "None" ]; then
    echo "❌ Erro ao obter QR Code"
    echo "Resposta: $QR_RESPONSE"
    echo ""
    echo "💡 SOLUÇÃO:"
    echo "   Acesse o painel Z-API: https://developer.z-api.io/"
    echo "   Entre na sua instância e gere um novo QR Code"
    exit 1
fi

echo "✅ QR Code obtido!"
echo ""

# Salvar QR Code em arquivo
echo "$QR_VALUE" > /tmp/zapi_qrcode.txt
echo "📱 QR Code salvo em: /tmp/zapi_qrcode.txt"
echo ""

# Gerar URL para visualizar QR Code
QR_URL="https://api.qrserver.com/v1/create-qr-code/?size=300x300&data=${QR_VALUE}"
echo "╔══════════════════════════════════════════════════════════════╗"
echo "║                                                              ║"
echo "║  📱 ESCANEIE O QR CODE COM SEU WHATSAPP                      ║"
echo "║                                                              ║"
echo "╚══════════════════════════════════════════════════════════════╝"
echo ""
echo "🌐 URL do QR Code:"
echo "   $QR_URL"
echo ""
echo "💡 COMO ESCANEAR:"
echo ""
echo "   1. Abra o WhatsApp no celular (número 5585996039026)"
echo "   2. Vá em: Configurações → Aparelhos conectados"
echo "   3. Toque em: Conectar um aparelho"
echo "   4. Escaneie o QR Code da URL acima"
echo ""
echo "    OU"
echo ""
echo "   Acesse esta URL no navegador para ver o QR Code:"
echo "   $QR_URL"
echo ""
echo "⏳ Aguardando conexão..."
echo "   (Pressione Ctrl+C para cancelar)"
echo ""

# Loop para verificar conexão
TIMEOUT=300  # 5 minutos
ELAPSED=0
INTERVAL=5

while [ $ELAPSED -lt $TIMEOUT ]; do
    sleep $INTERVAL
    ELAPSED=$((ELAPSED + INTERVAL))
    
    STATUS=$(curl -s -X GET "$BASE_URL/status" \
      -H "Client-Token: $CLIENT_TOKEN" \
      -H "Content-Type: application/json")
    
    CONNECTED=$(echo "$STATUS" | python3 -c "import sys, json; print(json.load(sys.stdin).get('connected', False))" 2>/dev/null)
    
    if [ "$CONNECTED" = "True" ]; then
        echo ""
        echo "╔══════════════════════════════════════════════════════════════╗"
        echo "║                                                              ║"
        echo "║  ✅ WHATSAPP CONECTADO COM SUCESSO!                           ║"
        echo "║                                                              ║"
        echo "╚══════════════════════════════════════════════════════════════╝"
        echo ""
        echo "$STATUS" | python3 -m json.tool
        exit 0
    fi
    
    echo -n "."
done

echo ""
echo "⏱️  Timeout: WhatsApp não foi conectado em 5 minutos"
echo "   Tente novamente ou acesse o painel Z-API manualmente"
echo ""

