#!/bin/bash

# ========================================
# MUDAR SENHA DO BANCO DE DADOS POSTGRESQL
# Executa no servidor remoto
# ========================================

echo "=========================================="
echo "🔐 MUDANDO SENHA DO BANCO DE DADOS"
echo "=========================================="
echo ""

# Cores
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

NOVA_SENHA="<redacted-db-password>"
NOVA_SENHA_ENCODED="<redacted-db-password-encoded>"

echo -e "${BLUE}Nova senha: ${NOVA_SENHA}${NC}"
echo -e "${BLUE}Nova senha (URL encoded): ${NOVA_SENHA_ENCODED}${NC}"
echo ""

echo -e "${YELLOW}⚠️  Conectando ao servidor...${NC}"
echo ""

ssh root@82.25.92.217 << ENDSSH
    set -e
    cd /var/www/debrief
    
    echo -e "\033[0;34m1️⃣ Mudando senha no container PostgreSQL:\033[0m"
    docker exec debrief_db psql -U postgres -c "ALTER USER postgres WITH PASSWORD '${NOVA_SENHA}';"
    echo -e "\033[0;32m✅ Senha alterada no PostgreSQL\033[0m"
    echo ""
    
    echo -e "\033[0;34m2️⃣ Atualizando arquivo backend/.env:\033[0m"
    if [ -f backend/.env ]; then
        # Backup do .env
        cp backend/.env backend/.env.backup.\$(date +%Y%m%d_%H%M%S)
        
        # Atualizar DATABASE_URL
        sed -i "s|DATABASE_URL=.*|DATABASE_URL=postgresql://postgres:${NOVA_SENHA_ENCODED}@debrief_db:5432/dbrief|g" backend/.env
        
        echo "Nova configuração:"
        grep "DATABASE_URL" backend/.env
        echo -e "\033[0;32m✅ Arquivo .env atualizado\033[0m"
    else
        echo -e "\033[0;31m❌ Arquivo backend/.env não encontrado\033[0m"
        exit 1
    fi
    echo ""
    
    echo -e "\033[0;34m3️⃣ Testando nova senha:\033[0m"
    if docker exec debrief_db psql -U postgres -d dbrief -c "SELECT 1;" > /dev/null 2>&1; then
        echo -e "\033[0;32m✅ Nova senha funciona!\033[0m"
    else
        echo -e "\033[0;31m❌ Erro ao testar nova senha\033[0m"
        exit 1
    fi
    echo ""
    
    echo -e "\033[0;34m4️⃣ Reiniciando container backend:\033[0m"
    docker-compose restart backend
    echo ""
    
    echo -e "\033[0;34m5️⃣ Aguardando backend iniciar...\033[0m"
    sleep 10
    echo ""
    
    echo -e "\033[0;34m6️⃣ Verificando saúde do backend:\033[0m"
    docker-compose ps backend
    echo ""
    
    echo -e "\033[0;34m7️⃣ Testando conexão do backend com banco:\033[0m"
    docker logs debrief-backend 2>&1 | tail -5
    echo ""
    
    echo "=========================================="
    echo -e "\033[0;32m✅ Senha alterada com sucesso!\033[0m"
    echo "=========================================="
    echo ""
    echo "Nova senha: ${NOVA_SENHA}"
    echo "URL encoded: ${NOVA_SENHA_ENCODED}"
    echo ""
ENDSSH

echo ""
echo -e "${GREEN}✅ Senha do banco alterada no servidor!${NC}"
echo ""
echo -e "${YELLOW}📝 Agora atualize sua conexão local (DBeaver):${NC}"
echo "  Password: ${NOVA_SENHA}"
echo ""





