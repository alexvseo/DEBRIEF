#!/bin/bash

echo "========================================="
echo "🧪 TESTE DOS ENDPOINTS /me"
echo "========================================="
echo ""

# Cores
GREEN='\033[0;32m'
RED='\033[0;31m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

SERVER="http://82.25.92.217:2023"

echo "📋 Passo 1: Fazer login para obter token"
echo ""

# Login com credenciais corretas
LOGIN_RESPONSE=$(curl -s -X POST "$SERVER/api/auth/login" \
  -H "Content-Type: application/x-www-form-urlencoded" \
  -d "username=admindb&password=Av2025@")

TOKEN=$(echo $LOGIN_RESPONSE | grep -o '"access_token":"[^"]*' | cut -d'"' -f4)

if [ -z "$TOKEN" ]; then
    echo -e "${RED}❌ Falha no login!${NC}"
    echo "Resposta: $LOGIN_RESPONSE"
    exit 1
fi

echo -e "${GREEN}✅ Login realizado com sucesso!${NC}"
echo "Token: ${TOKEN:0:30}..."
echo ""

echo "========================================="
echo "📋 Passo 2: Testar GET /api/usuarios/me"
echo ""

ME_RESPONSE=$(curl -s -w "\nHTTP_CODE:%{http_code}" -X GET "$SERVER/api/usuarios/me" \
  -H "Authorization: Bearer $TOKEN")

HTTP_CODE=$(echo "$ME_RESPONSE" | grep -o "HTTP_CODE:[0-9]*" | cut -d':' -f2)
RESPONSE_BODY=$(echo "$ME_RESPONSE" | sed 's/HTTP_CODE:[0-9]*$//')

echo "Status HTTP: $HTTP_CODE"
echo ""

if [ "$HTTP_CODE" = "200" ]; then
    echo -e "${GREEN}✅ GET /api/usuarios/me - SUCESSO!${NC}"
    echo ""
    echo "Resposta:"
    echo "$RESPONSE_BODY" | python3 -m json.tool 2>/dev/null || echo "$RESPONSE_BODY"
else
    echo -e "${RED}❌ GET /api/usuarios/me - FALHOU!${NC}"
    echo ""
    echo "Resposta:"
    echo "$RESPONSE_BODY"
fi

echo ""
echo "========================================="
echo "📋 Passo 3: Testar PUT /api/usuarios/me/notificacoes"
echo ""

UPDATE_RESPONSE=$(curl -s -w "\nHTTP_CODE:%{http_code}" -X PUT "$SERVER/api/usuarios/me/notificacoes" \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "whatsapp": "5585991042626",
    "receber_notificacoes": true
  }')

HTTP_CODE=$(echo "$UPDATE_RESPONSE" | grep -o "HTTP_CODE:[0-9]*" | cut -d':' -f2)
RESPONSE_BODY=$(echo "$UPDATE_RESPONSE" | sed 's/HTTP_CODE:[0-9]*$//')

echo "Status HTTP: $HTTP_CODE"
echo ""

if [ "$HTTP_CODE" = "200" ]; then
    echo -e "${GREEN}✅ PUT /api/usuarios/me/notificacoes - SUCESSO!${NC}"
    echo ""
    echo "Resposta:"
    echo "$RESPONSE_BODY" | python3 -m json.tool 2>/dev/null || echo "$RESPONSE_BODY"
else
    echo -e "${RED}❌ PUT /api/usuarios/me/notificacoes - FALHOU!${NC}"
    echo ""
    echo "Resposta:"
    echo "$RESPONSE_BODY"
fi

echo ""
echo "========================================="
echo "📋 Passo 4: Verificar se a atualização persistiu"
echo ""

VERIFY_RESPONSE=$(curl -s -w "\nHTTP_CODE:%{http_code}" -X GET "$SERVER/api/usuarios/me" \
  -H "Authorization: Bearer $TOKEN")

HTTP_CODE=$(echo "$VERIFY_RESPONSE" | grep -o "HTTP_CODE:[0-9]*" | cut -d':' -f2)
RESPONSE_BODY=$(echo "$VERIFY_RESPONSE" | sed 's/HTTP_CODE:[0-9]*$//')

if [ "$HTTP_CODE" = "200" ]; then
    WHATSAPP_NUMBER=$(echo "$RESPONSE_BODY" | grep -o '"whatsapp":"[^"]*' | cut -d'"' -f4)
    RECEBER_NOTIF=$(echo "$RESPONSE_BODY" | grep -o '"receber_notificacoes":[^,}]*' | cut -d':' -f2)
    
    echo -e "${BLUE}WhatsApp:${NC} $WHATSAPP_NUMBER"
    echo -e "${BLUE}Receber Notificações:${NC} $RECEBER_NOTIF"
    echo ""
    
    if [ "$WHATSAPP_NUMBER" = "5585991042626" ] && [ "$RECEBER_NOTIF" = "true" ]; then
        echo -e "${GREEN}✅ Dados atualizados corretamente!${NC}"
    else
        echo -e "${RED}⚠️  Dados não foram atualizados como esperado${NC}"
    fi
else
    echo -e "${RED}❌ Falha ao verificar dados atualizados${NC}"
fi

echo ""
echo "========================================="
echo "✅ TESTES CONCLUÍDOS!"
echo "========================================="

