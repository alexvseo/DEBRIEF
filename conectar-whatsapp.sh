#!/bin/bash

#
# Script para Conectar WhatsApp via Terminal
# Gera QR Code diretamente no terminal
#
# Data: 24/11/2025
#

set -e

# Cores para output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo ""
echo -e "${BLUE}╔═══════════════════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║      📱 CONECTAR WHATSAPP - DEBRIEF                  ║${NC}"
echo -e "${BLUE}╚═══════════════════════════════════════════════════════╝${NC}"
echo ""

# Credenciais
SERVER="82.25.92.217"
WPP_URL="https://wpp.interce.com.br"
API_KEY="debrief-wpp-58a2b7dda7da9474958e2a853062d5d5"
INSTANCE="debrief"

# Função para verificar se comando existe
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Verificar dependências
echo -e "${YELLOW}🔍 Verificando dependências...${NC}"

if ! command_exists curl; then
    echo -e "${RED}❌ curl não encontrado. Instale com: brew install curl${NC}"
    exit 1
fi

if ! command_exists jq; then
    echo -e "${YELLOW}⚠️  jq não encontrado. Instalando...${NC}"
    brew install jq
fi

echo -e "${GREEN}✅ Dependências OK${NC}"
echo ""

# 1. Verificar se Evolution API está online
echo -e "${YELLOW}🌐 Verificando Evolution API...${NC}"
if curl -s --max-time 10 "${WPP_URL}/" > /dev/null 2>&1; then
    echo -e "${GREEN}✅ Evolution API está online${NC}"
else
    echo -e "${RED}❌ Evolution API não está acessível${NC}"
    echo -e "${RED}   URL: ${WPP_URL}${NC}"
    exit 1
fi
echo ""

# 2. Verificar status da instância
echo -e "${YELLOW}📊 Verificando status da instância '${INSTANCE}'...${NC}"

STATUS_RESPONSE=$(ssh root@${SERVER} "curl -s 'http://localhost:21465/instance/fetchInstances?instanceName=${INSTANCE}' -H 'apikey: ${API_KEY}'")

if echo "$STATUS_RESPONSE" | jq -e '.[] | select(.instance.instanceName == "debrief")' > /dev/null 2>&1; then
    INSTANCE_STATE=$(echo "$STATUS_RESPONSE" | jq -r '.[0].instance.state')
    echo -e "${BLUE}   Estado atual: ${INSTANCE_STATE}${NC}"
    
    if [ "$INSTANCE_STATE" == "open" ]; then
        echo -e "${GREEN}✅ Instância já está conectada!${NC}"
        echo ""
        echo -e "${YELLOW}📱 Informações da conexão:${NC}"
        echo "$STATUS_RESPONSE" | jq '.[0].instance'
        echo ""
        exit 0
    fi
else
    echo -e "${RED}❌ Instância não encontrada${NC}"
    echo -e "${YELLOW}💡 Criando nova instância...${NC}"
    
    CREATE_RESPONSE=$(ssh root@${SERVER} "curl -s -X POST http://localhost:21465/instance/create \
      -H 'apikey: ${API_KEY}' \
      -H 'Content-Type: application/json' \
      -d '{\"instanceName\": \"${INSTANCE}\", \"integration\": \"WHATSAPP-BAILEYS\"}'")
    
    echo "$CREATE_RESPONSE" | jq .
    
    echo -e "${YELLOW}⏳ Aguardando 10 segundos para inicialização...${NC}"
    sleep 10
fi
echo ""

# 3. Conectar e gerar QR Code
echo -e "${YELLOW}🔗 Conectando à instância...${NC}"
echo ""

# Primeiro, tentar conectar
CONNECT_RESPONSE=$(ssh root@${SERVER} "curl -s -X GET 'http://localhost:21465/instance/connect/${INSTANCE}' \
  -H 'apikey: ${API_KEY}'")

echo -e "${BLUE}Resposta da conexão:${NC}"
echo "$CONNECT_RESPONSE" | jq . 2>/dev/null || echo "$CONNECT_RESPONSE"
echo ""

echo -e "${YELLOW}⏳ Aguardando 15 segundos para Baileys inicializar...${NC}"
sleep 15
echo ""

# 4. Buscar QR Code
echo -e "${YELLOW}📲 Gerando QR Code...${NC}"
echo ""
echo -e "${BLUE}════════════════════════════════════════════════════${NC}"
echo ""

# Loop para tentar pegar o QR Code (até 30 segundos)
TIMEOUT=30
ELAPSED=0

while [ $ELAPSED -lt $TIMEOUT ]; do
    QR_RESPONSE=$(ssh root@${SERVER} "curl -s 'http://localhost:21465/instance/fetchInstances?instanceName=${INSTANCE}' \
      -H 'apikey: ${API_KEY}'")
    
    # Verificar se tem QR Code
    QR_CODE=$(echo "$QR_RESPONSE" | jq -r '.[0].instance.qrcode.code // empty')
    
    if [ -n "$QR_CODE" ] && [ "$QR_CODE" != "null" ]; then
        echo -e "${GREEN}✅ QR Code gerado!${NC}"
        echo ""
        
        # Tentar mostrar QR Code no terminal
        if command_exists qrencode; then
            echo "$QR_CODE" | qrencode -t UTF8
            echo ""
        else
            echo -e "${YELLOW}⚠️  qrencode não instalado (para ver QR no terminal)${NC}"
            echo -e "${YELLOW}   Instale com: brew install qrencode${NC}"
            echo ""
            echo -e "${BLUE}📱 Alternativa: Use o Manager Web${NC}"
            echo "   https://wpp.interce.com.br/manager"
            echo ""
            echo -e "${BLUE}📱 Ou acesse esta URL no navegador:${NC}"
            echo ""
            
            # Gerar URL com QR Code base64
            QR_BASE64=$(echo "$QR_CODE" | base64)
            echo "   https://api.qrserver.com/v1/create-qr-code/?size=300x300&data=${QR_CODE}"
            echo ""
            
            # Salvar QR em arquivo
            echo "$QR_CODE" > /tmp/debrief_qrcode.txt
            echo -e "${GREEN}✅ QR Code salvo em: /tmp/debrief_qrcode.txt${NC}"
            echo ""
        fi
        
        echo -e "${BLUE}════════════════════════════════════════════════════${NC}"
        echo ""
        echo -e "${YELLOW}📱 COMO ESCANEAR:${NC}"
        echo ""
        echo "1. Abra o WhatsApp no celular (número 5585991042626)"
        echo "2. Vá em: Configurações → Aparelhos conectados"
        echo "3. Toque em: Conectar um aparelho"
        echo "4. Escaneie o QR Code"
        echo ""
        echo -e "${GREEN}✨ Após escanear, aguarde a confirmação!${NC}"
        echo ""
        
        # Aguardar conexão
        echo -e "${YELLOW}⏳ Aguardando conexão...${NC}"
        sleep 5
        
        # Verificar se conectou
        for i in {1..12}; do
            STATUS=$(ssh root@${SERVER} "curl -s 'http://localhost:21465/instance/fetchInstances?instanceName=${INSTANCE}' \
              -H 'apikey: ${API_KEY}'" | jq -r '.[0].instance.state')
            
            if [ "$STATUS" == "open" ]; then
                echo ""
                echo -e "${GREEN}╔═══════════════════════════════════════════════════════╗${NC}"
                echo -e "${GREEN}║           ✅ WHATSAPP CONECTADO COM SUCESSO!         ║${NC}"
                echo -e "${GREEN}╚═══════════════════════════════════════════════════════╝${NC}"
                echo ""
                
                # Buscar informações da conexão
                INFO=$(ssh root@${SERVER} "curl -s 'http://localhost:21465/instance/fetchInstances?instanceName=${INSTANCE}' \
                  -H 'apikey: ${API_KEY}'")
                
                echo -e "${YELLOW}📱 Informações da conexão:${NC}"
                echo "$INFO" | jq '.[0].instance | {instanceName, state, profileName, profilePictureUrl}'
                echo ""
                
                echo -e "${YELLOW}🎯 Próximos passos:${NC}"
                echo ""
                echo "1. Acesse: https://debrief.interce.com.br/admin/configuracao-whatsapp"
                echo "2. Configure o número remetente: 5585991042626"
                echo "3. Clique em 'Testar Conexão' para enviar mensagem de teste"
                echo ""
                
                exit 0
            fi
            
            echo -n "."
            sleep 5
        done
        
        echo ""
        echo -e "${YELLOW}⚠️  Tempo esgotado aguardando conexão${NC}"
        echo -e "${YELLOW}   Verifique se escaneou o QR Code corretamente${NC}"
        echo ""
        exit 1
    fi
    
    echo -n "."
    sleep 2
    ELAPSED=$((ELAPSED + 2))
done

echo ""
echo -e "${RED}❌ QR Code não foi gerado dentro do tempo limite${NC}"
echo ""
echo -e "${YELLOW}💡 Possíveis causas:${NC}"
echo "1. WhatsApp pode estar bloqueando temporariamente"
echo "2. Baileys ainda está inicializando"
echo "3. Instância precisa ser reiniciada"
echo ""
echo -e "${YELLOW}🔄 Tente novamente em alguns minutos${NC}"
echo ""

exit 1

