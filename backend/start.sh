#!/bin/bash

# Script para iniciar o backend DeBrief
# Uso: ./start.sh

echo "🚀 Iniciando DeBrief Backend..."
echo ""

# Cores
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

# Verificar se venv existe
if [ ! -d "venv" ]; then
    echo -e "${RED}❌ Ambiente virtual não encontrado!${NC}"
    echo "Execute: /opt/homebrew/bin/python3.11 -m venv venv"
    exit 1
fi

# Ativar venv
echo -e "${YELLOW}📦 Ativando ambiente virtual...${NC}"
source venv/bin/activate

# Verificar versão do Python
PYTHON_VERSION=$(python --version 2>&1 | awk '{print $2}')
echo -e "${GREEN}✅ Python $PYTHON_VERSION${NC}"

# Verificar se dependências estão instaladas
if ! python -c "import fastapi" 2>/dev/null; then
    echo -e "${YELLOW}📦 Instalando dependências...${NC}"
    pip install -r requirements.txt
fi

# Verificar PostgreSQL
if ! pg_isready -q 2>/dev/null; then
    echo -e "${YELLOW}⚠️  PostgreSQL não está rodando${NC}"
    echo "Execute: brew services start postgresql"
fi

echo ""
echo -e "${GREEN}✅ Iniciando servidor FastAPI...${NC}"
echo -e "${GREEN}📝 Documentação: http://localhost:8000/api/docs${NC}"
echo ""

# Iniciar servidor
uvicorn app.main:app --reload --host 0.0.0.0 --port 8000

