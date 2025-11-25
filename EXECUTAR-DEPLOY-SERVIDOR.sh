#!/bin/bash

############################################
# DEPLOY NO SERVIDOR - Passo Final
# Execute este script para aplicar as alterações no servidor
############################################

echo "════════════════════════════════════════════════════════════"
echo "   🚀 DEPLOY NO SERVIDOR - debrief.interce.com.br"
echo "════════════════════════════════════════════════════════════"
echo ""

# Cores
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
NC='\033[0m'

echo -e "${BLUE}📡 Conectando ao servidor 82.25.92.217...${NC}"
echo ""

ssh root@82.25.92.217 << 'ENDSSH'
    # Cores no servidor
    GREEN='\033[0;32m'
    BLUE='\033[0;34m'
    YELLOW='\033[1;33m'
    NC='\033[0m'
    
    echo -e "${BLUE}📂 Navegando para /var/www/debrief...${NC}"
    cd /var/www/debrief || exit 1
    
    echo ""
    echo -e "${BLUE}📦 Fazendo backup do arquivo atual...${NC}"
    cp frontend/src/pages/admin/ConfiguracaoWhatsApp.jsx \
       frontend/src/pages/admin/ConfiguracaoWhatsApp.jsx.backup-$(date +%Y%m%d-%H%M%S) 2>/dev/null || true
    
    echo ""
    echo -e "${BLUE}⬇️  Puxando alterações do GitHub...${NC}"
    git fetch origin
    git pull origin main
    
    if [ $? -ne 0 ]; then
        echo -e "${YELLOW}⚠️  Conflito detectado. Resolvendo...${NC}"
        git stash
        git pull origin main
    fi
    
    echo ""
    echo -e "${BLUE}✅ Verificando arquivo atualizado...${NC}"
    if grep -q "Evolution API" frontend/src/pages/admin/ConfiguracaoWhatsApp.jsx; then
        echo -e "${GREEN}✅ Arquivo ConfiguracaoWhatsApp.jsx atualizado com sucesso!${NC}"
    else
        echo -e "${YELLOW}⚠️  Arquivo pode não ter sido atualizado. Verificar manualmente.${NC}"
    fi
    
    if grep -q "NotificationService" backend/app/services/notification.py 2>/dev/null; then
        echo -e "${GREEN}✅ Arquivo notification.py encontrado!${NC}"
    else
        echo -e "${YELLOW}⚠️  Arquivo notification.py não encontrado.${NC}"
    fi
    
    echo ""
    echo -e "${BLUE}🔄 Reiniciando backend...${NC}"
    docker restart debrief-backend
    
    echo ""
    echo -e "${BLUE}🔄 Reiniciando frontend...${NC}"
    docker restart debrief-frontend
    
    echo ""
    echo -e "${YELLOW}⏳ Aguardando containers iniciarem (20 segundos)...${NC}"
    sleep 20
    
    echo ""
    echo -e "${BLUE}📊 Status dos containers:${NC}"
    docker ps | grep debrief | awk '{printf "   %-20s %-30s %s\n", $1, $2, $NF}'
    
    echo ""
    echo -e "${BLUE}📝 Últimos logs do backend:${NC}"
    echo "────────────────────────────────────────"
    docker logs debrief-backend --tail 15 2>&1 | grep -v "GET /health"
    
    echo ""
    echo -e "${BLUE}📝 Últimos logs do frontend:${NC}"
    echo "────────────────────────────────────────"
    docker logs debrief-frontend --tail 10
    
    echo ""
    echo -e "${GREEN}════════════════════════════════════════════════════════════${NC}"
    echo -e "${GREEN}   ✅ DEPLOY CONCLUÍDO NO SERVIDOR!${NC}"
    echo -e "${GREEN}════════════════════════════════════════════════════════════${NC}"
ENDSSH

echo ""
echo "════════════════════════════════════════════════════════════"
echo "   📱 PRÓXIMOS PASSOS"
echo "════════════════════════════════════════════════════════════"
echo ""
echo "1️⃣  Abrir navegador em MODO ANÔNIMO (Ctrl+Shift+N)"
echo ""
echo "2️⃣  Acessar:"
echo "    👉 https://debrief.interce.com.br/admin/configuracao-whatsapp"
echo ""
echo "3️⃣  Fazer HARD REFRESH:"
echo "    Windows/Linux: Ctrl + Shift + R"
echo "    Mac: Cmd + Shift + R"
echo ""
echo "4️⃣  Verificar se aparece:"
echo "    ✅ Status da Conexão (novo!)"
echo "    ✅ Número remetente: 5585991042626"
echo "    ✅ Instância: debrief"
echo "    ✅ Campo 'Seu Número WhatsApp' editável"
echo "    ✅ Campo 'Número para Teste' ATIVO"
echo ""
echo "════════════════════════════════════════════════════════════"
echo ""

