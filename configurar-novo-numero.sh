#!/bin/bash

#
# Script para Configurar Novo Número WhatsApp
# Cria uma nova instância sem interferir na existente
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
echo -e "${BLUE}╔═══════════════════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║      📱 CONFIGURAR NOVO NÚMERO WHATSAPP              ║${NC}"
echo -e "${BLUE}╚═══════════════════════════════════════════════════════╝${NC}"
echo ""

# Solicitar informações
read -p "Digite o NOVO número WhatsApp (ex: 5511999887766): " NUMERO

if [ -z "$NUMERO" ]; then
    echo -e "${RED}❌ Número não pode estar vazio!${NC}"
    exit 1
fi

# Validar formato do número (apenas dígitos)
if ! [[ "$NUMERO" =~ ^[0-9]+$ ]]; then
    echo -e "${RED}❌ Número inválido! Use apenas dígitos (ex: 5511999887766)${NC}"
    exit 1
fi

# Validar tamanho mínimo
if [ ${#NUMERO} -lt 12 ]; then
    echo -e "${RED}❌ Número muito curto! Use o formato completo: código país + DDD + número${NC}"
    echo -e "${YELLOW}   Exemplo Brasil: 5511999887766 (55 + 11 + 999887766)${NC}"
    exit 1
fi

echo ""
echo -e "${BLUE}Número a ser configurado: ${NUMERO}${NC}"
echo ""

# Definir nome da instância
INSTANCE_NAME="debrief-${NUMERO: -4}"  # Últimos 4 dígitos do número
echo -e "${YELLOW}Nome da instância: ${INSTANCE_NAME}${NC}"
echo ""

read -p "Deseja continuar? (s/n): " confirma
if [[ ! "$confirma" =~ ^[Ss]$ ]]; then
    echo -e "${YELLOW}Operação cancelada.${NC}"
    exit 0
fi

# Credenciais
SERVER="82.25.92.217"
API_KEY="debrief-wpp-58a2b7dda7da9474958e2a853062d5d5"

echo ""
echo -e "${YELLOW}🔍 Passo 1: Verificando Evolution API...${NC}"

if curl -s --max-time 10 "https://wpp.interce.com.br/" > /dev/null 2>&1; then
    echo -e "${GREEN}✅ Evolution API está online${NC}"
else
    echo -e "${RED}❌ Evolution API não está acessível${NC}"
    exit 1
fi

echo ""
echo -e "${YELLOW}🆕 Passo 2: Criando nova instância...${NC}"

CREATE_RESPONSE=$(ssh root@${SERVER} "curl -s -X POST 'http://localhost:21465/instance/create' \
  -H 'apikey: ${API_KEY}' \
  -H 'Content-Type: application/json' \
  -d '{
    \"instanceName\": \"${INSTANCE_NAME}\",
    \"integration\": \"WHATSAPP-BAILEYS\",
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

if echo "$CREATE_RESPONSE" | grep -q -E '"status":\s*201|"instance"'; then
    echo ""
    echo -e "${GREEN}✅ Instância criada com sucesso!${NC}"
    echo ""
    
    echo -e "${YELLOW}⏳ Aguardando 20 segundos para inicialização...${NC}"
    sleep 20
    
    echo ""
    echo -e "${YELLOW}🔗 Passo 3: Iniciando conexão...${NC}"
    
    CONNECT_RESPONSE=$(ssh root@${SERVER} "curl -s -X GET 'http://localhost:21465/instance/connect/${INSTANCE_NAME}' \
      -H 'apikey: ${API_KEY}'")
    
    echo "$CONNECT_RESPONSE" | jq . 2>/dev/null || echo "$CONNECT_RESPONSE"
    
    echo ""
    echo -e "${YELLOW}⏳ Aguardando 15 segundos para Baileys inicializar...${NC}"
    sleep 15
    
    echo ""
    echo -e "${BLUE}╔═══════════════════════════════════════════════════════╗${NC}"
    echo -e "${BLUE}║      ✅ INSTÂNCIA CRIADA - PRONTA PARA QR CODE       ║${NC}"
    echo -e "${BLUE}╚═══════════════════════════════════════════════════════╝${NC}"
    echo ""
    
    echo -e "${YELLOW}📱 PRÓXIMOS PASSOS:${NC}"
    echo ""
    echo "1️⃣  Abrir o Manager:"
    echo "   ${BLUE}https://wpp.interce.com.br/manager${NC}"
    echo ""
    echo "2️⃣  Login com:"
    echo "   Server URL: ${BLUE}https://wpp.interce.com.br${NC}"
    echo "   API Key: ${BLUE}${API_KEY}${NC}"
    echo ""
    echo "3️⃣  Localizar instância: ${BLUE}${INSTANCE_NAME}${NC}"
    echo ""
    echo "4️⃣  Clicar em: ${YELLOW}Get QR Code${NC}"
    echo ""
    echo "5️⃣  Aguardar 15-20 segundos"
    echo ""
    echo "6️⃣  Escanear QR Code com o WhatsApp do número:"
    echo "   ${GREEN}${NUMERO}${NC}"
    echo ""
    echo "7️⃣  No celular:"
    echo "   • Abrir WhatsApp"
    echo "   • Configurações → Aparelhos conectados"
    echo "   • Conectar um aparelho"
    echo "   • Escanear o QR Code"
    echo ""
    echo ""
    echo -e "${YELLOW}📝 IMPORTANTE: Atualizar Backend${NC}"
    echo ""
    echo "Após conectar, atualize as variáveis de ambiente:"
    echo ""
    echo -e "${BLUE}ssh root@${SERVER}${NC}"
    echo -e "${BLUE}cd /var/www/debrief/backend${NC}"
    echo -e "${BLUE}nano .env${NC}"
    echo ""
    echo "Altere:"
    echo "  WPP_INSTANCE=${INSTANCE_NAME}"
    echo ""
    echo "Reinicie o backend:"
    echo -e "${BLUE}cd /var/www/debrief && docker-compose restart backend${NC}"
    echo ""
    echo ""
    echo -e "${GREEN}🌐 Abrindo Manager no navegador em 5 segundos...${NC}"
    sleep 5
    
    open "https://wpp.interce.com.br/manager"
    
    echo ""
    echo -e "${GREEN}✅ Navegador aberto!${NC}"
    echo ""
    
    # Salvar configurações
    cat > /tmp/whatsapp_novo_numero.txt << EOF
╔══════════════════════════════════════════════════════════╗
║   📱 NOVA CONFIGURAÇÃO WHATSAPP                         ║
╚══════════════════════════════════════════════════════════╝

Número: ${NUMERO}
Instância: ${INSTANCE_NAME}
Data: $(date '+%d/%m/%Y %H:%M')

Configurações para .env:
  WPP_URL=https://wpp.interce.com.br
  WPP_INSTANCE=${INSTANCE_NAME}
  WPP_TOKEN=${API_KEY}

Manager URL: https://wpp.interce.com.br/manager

EOF
    
    echo -e "${BLUE}📄 Configurações salvas em: /tmp/whatsapp_novo_numero.txt${NC}"
    
else
    echo ""
    echo -e "${RED}❌ Erro ao criar instância${NC}"
    echo ""
    
    # Verificar se é erro de duplicação
    if echo "$CREATE_RESPONSE" | grep -q "already in use"; then
        echo -e "${YELLOW}💡 A instância já existe!${NC}"
        echo ""
        echo "Tente um destes comandos:"
        echo ""
        echo "1. Usar a instância existente:"
        echo "   ./conectar-whatsapp-browser.sh"
        echo ""
        echo "2. Deletar e recriar:"
        echo "   ./resetar-whatsapp.sh"
    fi
    
    exit 1
fi


