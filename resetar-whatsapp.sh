#!/bin/bash

#
# Script para Resetar Instância WhatsApp Completamente
# Remove todos os dados e cria instância limpa
#
# Data: 24/11/2025
#

set -e

# Cores
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
BLUE='\033[0;34m'
NC='\033[0m'

echo ""
echo -e "${RED}╔═══════════════════════════════════════════════════════╗${NC}"
echo -e "${RED}║      ⚠️  RESETAR INSTÂNCIA WHATSAPP - DEBRIEF        ║${NC}"
echo -e "${RED}╚═══════════════════════════════════════════════════════╝${NC}"
echo ""

SERVER="82.25.92.217"
API_KEY="debrief-wpp-58a2b7dda7da9474958e2a853062d5d5"
INSTANCE="debrief"

echo -e "${YELLOW}⚠️  ATENÇÃO: Esta operação irá:${NC}"
echo "   1. Deletar completamente a instância 'debrief'"
echo "   2. Remover todos os dados de conexão"
echo "   3. Criar uma instância nova e limpa"
echo ""
echo -e "${RED}   Esta operação NÃO pode ser desfeita!${NC}"
echo ""
read -p "Deseja continuar? (digite 'SIM' para confirmar): " confirma

if [ "$confirma" != "SIM" ]; then
    echo ""
    echo -e "${YELLOW}Operação cancelada.${NC}"
    echo ""
    exit 0
fi

echo ""
echo -e "${YELLOW}🗑️  Passo 1: Deletando instância antiga...${NC}"

DELETE_RESPONSE=$(ssh root@${SERVER} "curl -s -X DELETE 'http://localhost:21465/instance/delete/debrief' \
  -H 'apikey: ${API_KEY}'")

echo "$DELETE_RESPONSE" | jq . 2>/dev/null || echo "$DELETE_RESPONSE"
echo ""

echo -e "${YELLOW}⏳ Aguardando 10 segundos...${NC}"
sleep 10

echo -e "${YELLOW}🆕 Passo 2: Criando nova instância...${NC}"

CREATE_RESPONSE=$(ssh root@${SERVER} "curl -s -X POST 'http://localhost:21465/instance/create' \
  -H 'apikey: ${API_KEY}' \
  -H 'Content-Type: application/json' \
  -d '{
    \"instanceName\": \"${INSTANCE}\",
    \"integration\": \"WHATSAPP-BAILEYS\",
    \"number\": \"5585991042626\",
    \"qrcode\": true,
    \"reject_call\": false,
    \"msg_call\": \"\",
    \"groups_ignore\": false,
    \"always_online\": false,
    \"read_messages\": false,
    \"read_status\": false,
    \"sync_full_history\": false
  }'")

echo "$CREATE_RESPONSE" | jq . 2>/dev/null || echo "$CREATE_RESPONSE"
echo ""

if echo "$CREATE_RESPONSE" | grep -q '"status"'; then
    STATUS=$(echo "$CREATE_RESPONSE" | jq -r '.status // "unknown"')
    
    if [ "$STATUS" == "201" ] || echo "$CREATE_RESPONSE" | grep -q '"instance"'; then
        echo -e "${GREEN}✅ Instância criada com sucesso!${NC}"
        echo ""
        
        echo -e "${YELLOW}⏳ Aguardando 15 segundos para inicialização...${NC}"
        sleep 15
        
        echo ""
        echo -e "${BLUE}╔═══════════════════════════════════════════════════════╗${NC}"
        echo -e "${BLUE}║      ✅ INSTÂNCIA RESETADA COM SUCESSO!              ║${NC}"
        echo -e "${BLUE}╚═══════════════════════════════════════════════════════╝${NC}"
        echo ""
        
        echo -e "${YELLOW}📝 IMPORTANTE:${NC}"
        echo ""
        echo "1. Aguarde PELO MENOS 2-3 HORAS antes de tentar conectar"
        echo "2. Isso dá tempo para o WhatsApp 'esquecer' o bloqueio"
        echo "3. Quando for conectar, use:"
        echo "   ./conectar-whatsapp-browser.sh"
        echo ""
        echo -e "${YELLOW}💡 Dica: Tente conectar amanhã pela manhã (25/11)${NC}"
        echo ""
    else
        echo -e "${RED}❌ Erro ao criar instância${NC}"
        echo "$CREATE_RESPONSE"
        exit 1
    fi
else
    echo -e "${RED}❌ Resposta inesperada${NC}"
    echo "$CREATE_RESPONSE"
    exit 1
fi




