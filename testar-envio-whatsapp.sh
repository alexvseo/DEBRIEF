#!/bin/bash

# 🧪 Testar envio de mensagem via Evolution API (Baileys)

echo ""
echo "╔══════════════════════════════════════════════════════════════╗"
echo "║                                                              ║"
echo "║  🧪 TESTE DE ENVIO - WHATSAPP EVOLUTION API (BAILEYS)        ║"
echo "║                                                              ║"
echo "╚══════════════════════════════════════════════════════════════╝"
echo ""

SERVER="root@82.25.92.217"
APIKEY="debrief-wpp-58a2b7dda7da9474958e2a853062d5d5"
PORT="21465"
INSTANCE="debrief"

echo "📊 Verificando status da conexão..."
STATUS=$(ssh $SERVER "curl -s 'http://localhost:$PORT/instance/connectionState/$INSTANCE' \
    -H 'apikey: $APIKEY' | python3 -c 'import sys, json; print(json.load(sys.stdin)[\"instance\"][\"state\"])'")

if [ "$STATUS" != "open" ]; then
    echo "❌ WhatsApp não conectado! Status: $STATUS"
    echo "   Execute: ./reconectar-whatsapp-evolution.sh"
    exit 1
fi

echo "✅ WhatsApp conectado!"
echo ""

# Pedir número do WhatsApp
echo "📱 Digite o número do WhatsApp para teste (ex: 5511999999999):"
read -p "   Número: " NUMERO

if [ -z "$NUMERO" ]; then
    echo "❌ Número não informado!"
    exit 1
fi

# Limpar número (só dígitos)
NUMERO_LIMPO=$(echo "$NUMERO" | tr -d -c 0-9)

# Validar se tem pelo menos 10 dígitos
if [ ${#NUMERO_LIMPO} -lt 10 ]; then
    echo "❌ Número inválido! Deve ter pelo menos 10 dígitos."
    exit 1
fi

# Adicionar @s.whatsapp.net
CHAT_ID="${NUMERO_LIMPO}@s.whatsapp.net"

echo ""
echo "🔄 Enviando mensagem de teste..."
echo "   Para: $CHAT_ID"
echo ""

# Enviar mensagem
RESPONSE=$(ssh $SERVER "curl -s -X POST 'http://localhost:$PORT/message/sendText/$INSTANCE' \
    -H 'apikey: $APIKEY' \
    -H 'Content-Type: application/json' \
    -d '{
        \"number\": \"$NUMERO_LIMPO\",
        \"text\": \"🎉 *DeBrief - Teste de Conexão*\n\n✅ WhatsApp conectado via Evolution API (Baileys)!\n\n_Mensagem automática de teste do sistema DeBrief_\n\n🕐 $(date '+%d/%m/%Y %H:%M:%S')\"
    }' | python3 -m json.tool")

echo "$RESPONSE"
echo ""

# Verificar se enviou com sucesso
if echo "$RESPONSE" | grep -q '"key"'; then
    echo "╔══════════════════════════════════════════════════════════════╗"
    echo "║                                                              ║"
    echo "║  ✅ MENSAGEM ENVIADA COM SUCESSO!                            ║"
    echo "║                                                              ║"
    echo "║  O WhatsApp está 100% operacional via Baileys! 🎉           ║"
    echo "║                                                              ║"
    echo "╚══════════════════════════════════════════════════════════════╝"
else
    echo "╔══════════════════════════════════════════════════════════════╗"
    echo "║                                                              ║"
    echo "║  ⚠️  ERRO NO ENVIO                                           ║"
    echo "║                                                              ║"
    echo "║  Verifique a resposta acima para mais detalhes              ║"
    echo "║                                                              ║"
    echo "╚══════════════════════════════════════════════════════════════╝"
    exit 1
fi

echo ""
echo "📋 Quer testar envio para grupo? (s/n)"
read -p "   Resposta: " GRUPO

if [ "$GRUPO" = "s" ] || [ "$GRUPO" = "S" ]; then
    echo ""
    echo "📱 Digite o ID do grupo (ex: 120363123456789012@g.us):"
    read -p "   ID: " GROUP_ID
    
    if [ -z "$GROUP_ID" ]; then
        echo "⚠️ ID não informado. Pulando teste de grupo."
    else
        echo ""
        echo "🔄 Enviando para grupo..."
        
        ssh $SERVER "curl -s -X POST 'http://localhost:$PORT/message/sendText/$INSTANCE' \
            -H 'apikey: $APIKEY' \
            -H 'Content-Type: application/json' \
            -d '{
                \"number\": \"$GROUP_ID\",
                \"text\": \"🎉 *DeBrief - Teste de Grupo*\n\n✅ Sistema operacional!\n\n_$(date '+%d/%m/%Y %H:%M:%S')_\"
            }' | python3 -m json.tool"
        
        echo ""
        echo "✅ Comando enviado para grupo!"
    fi
fi

echo ""

