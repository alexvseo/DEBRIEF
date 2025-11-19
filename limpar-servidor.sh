#!/bin/bash

# Script para Limpar Servidor - DeBrief
# Remove containers, imagens, volumes e cache do Docker
# Execute com cuidado: ./limpar-servidor.sh

set -e

# Cores
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

echo "=========================================="
echo "🧹 LIMPEZA DO SERVIDOR - DeBrief"
echo "=========================================="
echo ""
echo -e "${RED}⚠️  ATENÇÃO: Este script irá remover:${NC}"
echo "   - Todos os containers do DeBrief"
echo "   - Todas as imagens do DeBrief"
echo "   - Volumes não usados (opcional)"
echo "   - Cache do Docker (opcional)"
echo ""
read -p "Deseja continuar? (s/N): " confirm
if [ "$confirm" != "s" ] && [ "$confirm" != "S" ]; then
    echo "Operação cancelada."
    exit 0
fi
echo ""

# 1. Parar e remover containers
echo -e "${BLUE}1️⃣  Parando e removendo containers...${NC}"
docker-compose down -v --remove-orphans 2>/dev/null || true
echo -e "${GREEN}✅ Containers removidos${NC}"
echo ""

# 2. Remover imagens do projeto
echo -e "${BLUE}2️⃣  Removendo imagens do DeBrief...${NC}"
docker rmi debrief-backend:latest 2>/dev/null || echo "   Imagem backend não encontrada"
docker rmi debrief-frontend:latest 2>/dev/null || echo "   Imagem frontend não encontrada"
docker rmi caddy:2 2>/dev/null || echo "   Imagem caddy não encontrada"
echo -e "${GREEN}✅ Imagens removidas${NC}"
echo ""

# 3. Remover volumes (opcional)
read -p "Remover volumes não usados? (s/N): " confirm_volumes
if [ "$confirm_volumes" = "s" ] || [ "$confirm_volumes" = "S" ]; then
    echo -e "${BLUE}3️⃣  Removendo volumes não usados...${NC}"
    docker volume prune -f
    echo -e "${GREEN}✅ Volumes removidos${NC}"
else
    echo -e "${YELLOW}⚠️  Volumes mantidos${NC}"
fi
echo ""

# 4. Limpar cache do builder (opcional)
read -p "Limpar cache do Docker builder? (s/N): " confirm_cache
if [ "$confirm_cache" = "s" ] || [ "$confirm_cache" = "S" ]; then
    echo -e "${BLUE}4️⃣  Limpando cache do builder...${NC}"
    docker builder prune -f
    echo -e "${GREEN}✅ Cache limpo${NC}"
else
    echo -e "${YELLOW}⚠️  Cache mantido${NC}"
fi
echo ""

# 5. Limpar imagens não usadas (opcional)
read -p "Remover imagens não usadas? (s/N): " confirm_images
if [ "$confirm_images" = "s" ] || [ "$confirm_images" = "S" ]; then
    echo -e "${BLUE}5️⃣  Removendo imagens não usadas...${NC}"
    docker image prune -a -f
    echo -e "${GREEN}✅ Imagens não usadas removidas${NC}"
else
    echo -e "${YELLOW}⚠️  Imagens mantidas${NC}"
fi
echo ""

# 6. Verificar espaço liberado
echo -e "${BLUE}6️⃣  Espaço em disco após limpeza:${NC}"
df -h / | tail -1
echo ""

echo "=========================================="
echo -e "${GREEN}✅ Limpeza concluída!${NC}"
echo "=========================================="
echo ""
echo "📝 Próximos passos:"
echo "   1. Execute: ./rebuild-completo.sh"
echo "   2. Ou: docker-compose build --no-cache"
echo "   3. Depois: docker-compose up -d"
echo ""

