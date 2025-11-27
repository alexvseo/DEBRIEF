#!/bin/bash

# ========================================
# TÚNEL SSH PARA BANCO DE DADOS DEBRIEF
# Conecta ao CONTAINER debrief_db (banco correto com 12 demandas)
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

echo -e "${BLUE}Configuração do Túnel:${NC}"
echo "  Servidor: 82.25.92.217"
echo "  Banco: Container debrief_db (Docker)"
echo "  Porta Local: 5433 → Container debrief_db:5432"
echo "  Keep-Alive: Ativo (60 segundos)"
echo ""

echo -e "${GREEN}✅ Este é o banco CORRETO usado pelo site (12 demandas)${NC}"
echo ""

echo -e "${YELLOW}⚠️  IMPORTANTE:${NC}"
echo "Mantenha este terminal ABERTO enquanto usar o DBeaver!"
echo ""

echo -e "${CYAN}═══════════════════════════════════════${NC}"
echo -e "${GREEN}📝 CONFIGURAÇÃO DBEAVER:${NC}"
echo -e "${CYAN}═══════════════════════════════════════${NC}"
echo -e "${CYAN}  Host:     localhost${NC}"
echo -e "${CYAN}  Port:     5433${NC}"
echo -e "${CYAN}  Database: dbrief${NC}"
echo -e "${CYAN}  Username: postgres${NC}"
echo -e "${CYAN}  Password: <redacted-db-password>${NC}"
echo -e "${CYAN}═══════════════════════════════════════${NC}"
echo ""

echo -e "${BLUE}Conectando ao servidor...${NC}"
echo "Pressione Ctrl+C para encerrar o túnel"
echo ""
echo "=========================================="
echo ""

# Primeiro, criar túnel SSH e então port forward para o container
# Como o container está em uma rede Docker interna, precisamos fazer isso em 2 etapas:
# 1. SSH para o servidor
# 2. Do servidor, acessar o container debrief_db na porta 5432

# Usar dynamic port forwarding com docker exec
ssh -N -L 5433:172.19.0.2:5432 \
    -o ServerAliveInterval=60 \
    -o ServerAliveCountMax=3 \
    -o TCPKeepAlive=yes \
    -o ExitOnForwardFailure=yes \
    -o ConnectTimeout=10 \
    root@82.25.92.217

# Se o SSH encerrar, mostrar mensagem
echo ""
echo -e "${YELLOW}⚠️  Túnel SSH encerrado${NC}"
echo ""

