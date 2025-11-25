#!/bin/bash

#
# Script para Conectar WhatsApp via Navegador
# Abre o Evolution API Manager
#
# Data: 24/11/2025
#

# Cores para output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

echo ""
echo -e "${BLUE}╔═══════════════════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║      📱 CONECTAR WHATSAPP VIA NAVEGADOR              ║${NC}"
echo -e "${BLUE}╚═══════════════════════════════════════════════════════╝${NC}"
echo ""

SERVER="82.25.92.217"
MANAGER_URL="https://wpp.interce.com.br/manager"
API_KEY="debrief-wpp-58a2b7dda7da9474958e2a853062d5d5"
INSTANCE="debrief"

# Verificar status da instância
echo -e "${YELLOW}📊 Verificando status da instância...${NC}"
STATUS=$(ssh root@${SERVER} "curl -s 'http://localhost:21465/instance/fetchInstances?instanceName=${INSTANCE}' -H 'apikey: ${API_KEY}'" 2>/dev/null)

if [ -n "$STATUS" ]; then
    STATE=$(echo "$STATUS" | jq -r '.[0].instance.state // "unknown"')
    echo -e "${BLUE}   Estado atual: ${STATE}${NC}"
    
    if [ "$STATE" == "open" ]; then
        echo -e "${GREEN}✅ WhatsApp já está conectado!${NC}"
        echo ""
        echo "$STATUS" | jq '.[0].instance | {instanceName, state, profileName}'
        echo ""
        exit 0
    fi
fi
echo ""

# Instruções
echo -e "${YELLOW}📋 PASSOS PARA CONECTAR:${NC}"
echo ""
echo "1️⃣  O navegador abrirá com o Evolution API Manager"
echo "2️⃣  Faça login com:"
echo "    ${BLUE}Server URL:${NC} https://wpp.interce.com.br"
echo "    ${BLUE}API Key:${NC} ${API_KEY}"
echo ""
echo "3️⃣  Na lista de instâncias, localize: ${BLUE}debrief${NC}"
echo "4️⃣  Clique no botão laranja: ${YELLOW}Get QR Code${NC}"
echo "5️⃣  ${RED}AGUARDE 15-20 SEGUNDOS${NC} com o modal aberto"
echo "6️⃣  O QR Code deve aparecer"
echo ""
echo "7️⃣  No celular (${BLUE}5585991042626${NC}):"
echo "    • Abra WhatsApp"
echo "    • Configurações → Aparelhos conectados"
echo "    • Conectar um aparelho"
echo "    • Escaneie o QR Code"
echo ""
echo -e "${GREEN}✨ Pronto! O status deve mudar para 'Connected'${NC}"
echo ""
echo ""
echo -e "${YELLOW}⚠️  IMPORTANTE:${NC}"
echo "   • Se o QR não aparecer, aguarde mais 30 segundos"
echo "   • Se ainda não aparecer, clique em RESTART e tente novamente"
echo "   • Evite múltiplas tentativas seguidas (WhatsApp pode bloquear)"
echo ""
echo ""
echo -e "${BLUE}Abrindo navegador em 5 segundos...${NC}"
sleep 5

# Abrir navegador
open "${MANAGER_URL}"

echo ""
echo -e "${GREEN}✅ Navegador aberto!${NC}"
echo ""
echo -e "${YELLOW}💡 Após conectar, teste no DeBrief:${NC}"
echo "   https://debrief.interce.com.br/admin/configuracao-whatsapp"
echo ""

