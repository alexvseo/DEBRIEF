#!/bin/bash

# ========================================
# CONFIGURAR ACESSO REMOTO AO POSTGRESQL
# Execute este script NO SERVIDOR para permitir acesso via DBeaver
# ========================================

echo "=========================================="
echo "🔧 CONFIGURANDO ACESSO REMOTO AO POSTGRESQL"
echo "=========================================="
echo ""

# Cores
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Verificar se é root
if [ "$EUID" -ne 0 ]; then 
    echo -e "${RED}❌ Este script precisa ser executado como root${NC}"
    echo "Execute: sudo bash configurar-acesso-remoto-banco.sh"
    exit 1
fi

cd /var/www/debrief

echo -e "${BLUE}1️⃣ Verificando se há container debrief_db:${NC}"
if docker ps | grep -q "debrief_db"; then
    echo -e "${YELLOW}⚠️  Banco está em CONTAINER Docker${NC}"
    echo ""
    echo "OPÇÃO 1: Criar túnel SSH (RECOMENDADO)"
    echo "---------------------------------------"
    echo "No seu computador local, execute:"
    echo ""
    echo "ssh -L 5432:localhost:5432 root@82.25.92.217"
    echo ""
    echo "Depois configure o DBeaver com:"
    echo "  Host: localhost"
    echo "  Port: 5432"
    echo "  Database: dbrief"
    echo "  Username: postgres"
    echo "  Password: <redacted-db-password>"
    echo ""
    echo "OPÇÃO 2: Expor porta do container (NÃO RECOMENDADO)"
    echo "----------------------------------------------------"
    echo "Edite docker-compose.prod.yml e adicione na seção debrief_db:"
    echo "  ports:"
    echo "    - '5432:5432'"
    echo ""
    
elif systemctl is-active --quiet postgresql; then
    echo -e "${GREEN}✅ PostgreSQL está rodando como serviço do sistema${NC}"
    echo ""
    
    # Encontrar versão do PostgreSQL
    PG_VERSION=$(ls /etc/postgresql/ 2>/dev/null | head -1)
    
    if [ -z "$PG_VERSION" ]; then
        echo -e "${RED}❌ Não foi possível detectar a versão do PostgreSQL${NC}"
        exit 1
    fi
    
    echo -e "${BLUE}2️⃣ PostgreSQL versão detectada: ${PG_VERSION}${NC}"
    echo ""
    
    PG_CONF="/etc/postgresql/${PG_VERSION}/main/postgresql.conf"
    PG_HBA="/etc/postgresql/${PG_VERSION}/main/pg_hba.conf"
    
    # Backup dos arquivos
    echo -e "${BLUE}3️⃣ Criando backup das configurações:${NC}"
    cp "$PG_CONF" "${PG_CONF}.backup.$(date +%Y%m%d_%H%M%S)"
    cp "$PG_HBA" "${PG_HBA}.backup.$(date +%Y%m%d_%H%M%S)"
    echo "✅ Backups criados"
    echo ""
    
    # Configurar postgresql.conf
    echo -e "${BLUE}4️⃣ Configurando postgresql.conf:${NC}"
    if grep -q "^listen_addresses" "$PG_CONF"; then
        sed -i "s/^listen_addresses.*/listen_addresses = '*'/" "$PG_CONF"
    else
        echo "listen_addresses = '*'" >> "$PG_CONF"
    fi
    echo "✅ PostgreSQL configurado para aceitar conexões de qualquer IP"
    echo ""
    
    # Configurar pg_hba.conf
    echo -e "${BLUE}5️⃣ Configurando pg_hba.conf:${NC}"
    
    # Remover linhas antigas se existirem
    sed -i '/# DeBrief remote access/d' "$PG_HBA"
    sed -i '/host.*all.*all.*0.0.0.0\/0.*md5/d' "$PG_HBA"
    
    # Adicionar nova regra
    echo "" >> "$PG_HBA"
    echo "# DeBrief remote access" >> "$PG_HBA"
    echo "host    all             all             0.0.0.0/0               md5" >> "$PG_HBA"
    
    echo "✅ Acesso remoto configurado no pg_hba.conf"
    echo ""
    
    # Configurar firewall
    echo -e "${BLUE}6️⃣ Configurando firewall (UFW):${NC}"
    if command -v ufw &> /dev/null; then
        ufw allow 5432/tcp
        echo "✅ Porta 5432 liberada no firewall"
    else
        echo -e "${YELLOW}⚠️  UFW não instalado - configure o firewall manualmente${NC}"
    fi
    echo ""
    
    # Reiniciar PostgreSQL
    echo -e "${BLUE}7️⃣ Reiniciando PostgreSQL:${NC}"
    systemctl restart postgresql
    
    if systemctl is-active --quiet postgresql; then
        echo "✅ PostgreSQL reiniciado com sucesso"
    else
        echo -e "${RED}❌ Erro ao reiniciar PostgreSQL${NC}"
        echo "Restaurando backups..."
        cp "${PG_CONF}.backup."* "$PG_CONF"
        cp "${PG_HBA}.backup."* "$PG_HBA"
        systemctl restart postgresql
        exit 1
    fi
    echo ""
    
    # Testar conexão
    echo -e "${BLUE}8️⃣ Testando configuração:${NC}"
    ss -tuln | grep 5432
    echo ""
    
    echo "=========================================="
    echo -e "${GREEN}✅ CONFIGURAÇÃO CONCLUÍDA!${NC}"
    echo "=========================================="
    echo ""
    echo "Configure o DBeaver com:"
    echo "  Host: 82.25.92.217"
    echo "  Port: 5432"
    echo "  Database: dbrief"
    echo "  Username: postgres"
    echo "  Password: <redacted-db-password>"
    echo ""
    echo -e "${YELLOW}⚠️  AVISO DE SEGURANÇA:${NC}"
    echo "O banco está agora acessível remotamente."
    echo "Recomendamos restringir o acesso apenas ao seu IP."
    echo ""
    echo "Para restringir ao seu IP, edite $PG_HBA"
    echo "e substitua '0.0.0.0/0' pelo seu IP específico."
    echo ""
    
else
    echo -e "${RED}❌ PostgreSQL não encontrado${NC}"
    echo "O banco pode estar em outro lugar ou não estar instalado."
    exit 1
fi





