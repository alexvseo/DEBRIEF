#!/bin/bash

# 🔄 Reconectar WhatsApp no Evolution API (Baileys)
# Gera QR Code para escanear

echo ""
echo "╔══════════════════════════════════════════════════════════════╗"
echo "║                                                              ║"
echo "║  🔄 RECONECTANDO WHATSAPP - EVOLUTION API (BAILEYS)          ║"
echo "║                                                              ║"
echo "╚══════════════════════════════════════════════════════════════╝"
echo ""

SERVER="root@82.25.92.217"
APIKEY="debrief-wpp-58a2b7dda7da9474958e2a853062d5d5"
PORT="21465"

echo "📱 Passo 1: Deletando instância antiga..."
ssh $SERVER "curl -s -X DELETE 'http://localhost:$PORT/instance/delete/debrief' \
    -H 'apikey: $APIKEY' > /dev/null 2>&1"
echo "   ✅ Instância deletada"
echo ""

sleep 2

echo "🆕 Passo 2: Criando nova instância com Baileys..."
ssh $SERVER "curl -s -X POST 'http://localhost:$PORT/instance/create' \
    -H 'apikey: $APIKEY' \
    -H 'Content-Type: application/json' \
    -d '{
        \"instanceName\": \"debrief\",
        \"integration\": \"WHATSAPP-BAILEYS\",
        \"qrcode\": true
    }' | python3 -m json.tool"
echo ""

echo "⏳ Aguardando QR Code ser gerado..."
sleep 5
echo ""

echo "╔══════════════════════════════════════════════════════════════╗"
echo "║                                                              ║"
echo "║  📱 ESCANEIE O QR CODE ABAIXO COM SEU WHATSAPP               ║"
echo "║                                                              ║"
echo "╚══════════════════════════════════════════════════════════════╝"
echo ""

# Buscar QR Code
ssh $SERVER "curl -s 'http://localhost:$PORT/instance/fetchInstances?instanceName=debrief' \
    -H 'apikey: $APIKEY' | python3 -c \"
import sys
import json

data = json.load(sys.stdin)
if data and len(data) > 0:
    instance = data[0]['instance']
    qr_base64 = instance.get('qrcode', {}).get('base64', '')
    
    if qr_base64:
        # Extrair apenas o código base64 (sem o prefixo data:image/png;base64,)
        if 'base64,' in qr_base64:
            qr_base64 = qr_base64.split('base64,')[1]
        
        # Salvar em arquivo temporário
        import base64
        qr_data = base64.b64decode(qr_base64)
        with open('/tmp/qrcode_debrief.png', 'wb') as f:
            f.write(qr_data)
        print('✅ QR Code salvo em /tmp/qrcode_debrief.png')
    else:
        print('⚠️ QR Code ainda não disponível')
\""

echo ""
echo "🔍 Verificando status da conexão..."
sleep 3

ssh $SERVER "curl -s 'http://localhost:$PORT/instance/connectionState/debrief' \
    -H 'apikey: $APIKEY' | python3 -m json.tool"

echo ""
echo "╔══════════════════════════════════════════════════════════════╗"
echo "║                                                              ║"
echo "║  📋 INSTRUÇÕES:                                              ║"
echo "║                                                              ║"
echo "║  1. Baixe o QR Code do servidor:                            ║"
echo "║     scp root@82.25.92.217:/tmp/qrcode_debrief.png ~/Downloads/  ║"
echo "║                                                              ║"
echo "║  2. Abra o WhatsApp no celular                              ║"
echo "║  3. Vá em Configurações > Aparelhos conectados              ║"
echo "║  4. Toque em \"Conectar um aparelho\"                        ║"
echo "║  5. Escaneie o QR Code da imagem baixada                    ║"
echo "║                                                              ║"
echo "║  ⏱️  O QR Code expira em 60 segundos!                        ║"
echo "║                                                              ║"
echo "╚══════════════════════════════════════════════════════════════╝"
echo ""


