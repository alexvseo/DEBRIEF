#!/bin/bash

# ========================================
# TÚNEL SSH PARA O BANCO CORRETO
# Conecta automaticamente ao container debrief_db
# ========================================

echo "=========================================="
echo "🔐 CONECTANDO AO BANCO CORRETO (debrief_db)"
echo "=========================================="
echo ""

# Cores
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
RED='\033[0;31m'
NC='\033[0m' # No Color

echo -e "${BLUE}1️⃣ Descobrindo IP do container debrief_db...${NC}"

# Pegar IP do container debrief_db no servidor
CONTAINER_IP=$(ssh root@82.25.92.217 "docker inspect -f '{{range .NetworkSettings.Networks}}{{.IPAddress}}{{end}}' debrief_db" 2>/dev/null)

if [ -z "$CONTAINER_IP" ]; then
    echo -e "${RED}❌ Erro: Não foi possível encontrar o container debrief_db${NC}"
    echo "Verifique se o container está rodando no servidor"
    exit 1
fi

echo -e "${GREEN}✅ Container encontrado: ${CONTAINER_IP}${NC}"
echo ""

echo -e "${BLUE}2️⃣ Configuração do Túnel:${NC}"
echo "  Servidor: 82.25.92.217"
echo "  Container: debrief_db (${CONTAINER_IP}:5432)"
echo "  Porta Local: 5433 → Container:5432"
echo "  Keep-Alive: Ativo (60 segundos)"
echo ""

echo -e "${GREEN}✅ Este é o banco CORRETO usado pelo site (12 demandas)${NC}"
echo ""

echo -e "${YELLOW}⚠️  IMPORTANTE:${NC}"
echo "Se você já configurou o DBeaver antes, ATUALIZE:"
echo "- Porta: Use 5433 (não 5432)"
echo "- Senha: <redacted-db-password>"
echo ""

echo -e "${CYAN}═══════════════════════════════════════════${NC}"
echo -e "${GREEN}📝 CONFIGURAÇÃO DBEAVER (ATUALIZADA):${NC}"
echo -e "${CYAN}═══════════════════════════════════════════${NC}"
echo -e "${CYAN}  Host:     localhost${NC}"
echo -e "${YELLOW}  Port:     5433${NC}"
echo -e "${CYAN}  Database: dbrief${NC}"
echo -e "${CYAN}  Username: postgres${NC}"
echo -e "${YELLOW}  Password: <redacted-db-password>${NC}"
echo -e "${CYAN}═══════════════════════════════════════════${NC}"
echo ""

echo -e "${BLUE}3️⃣ Iniciando túnel SSH...${NC}"
echo "Mantenha este terminal ABERTO!"
echo "Pressione Ctrl+C para encerrar"
echo ""
echo "=========================================="
echo ""

# Criar túnel SSH para o container
ssh -N -L 5433:${CONTAINER_IP}:5432 \
    -o ServerAliveInterval=60 \
    -o ServerAliveCountMax=3 \
    -o TCPKeepAlive=yes \
    -o ExitOnForwardFailure=yes \
    -o ConnectTimeout=10 \
    root@82.25.92.217

# Se o SSH encerrar
echo ""
echo -e "${YELLOW}⚠️  Túnel SSH encerrado${NC}"
echo ""

