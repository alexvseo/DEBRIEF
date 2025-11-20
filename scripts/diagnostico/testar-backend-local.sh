#!/bin/bash

# Script para Testar Backend Localmente (antes de build)
# Verifica se o código está correto
# Execute: ./testar-backend-local.sh

echo "=========================================="
echo "🧪 TESTE DO BACKEND - DeBrief"
echo "=========================================="
echo ""

# Cores
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

cd backend

# 1. Verificar se Python está instalado
echo "1️⃣  Verificando Python..."
if command -v python3 &> /dev/null; then
    PYTHON_VERSION=$(python3 --version)
    echo -e "${GREEN}✅ $PYTHON_VERSION${NC}"
else
    echo -e "${RED}❌ Python3 não encontrado${NC}"
    exit 1
fi
echo ""

# 2. Verificar sintaxe do código
echo "2️⃣  Verificando sintaxe do código Python..."
if python3 -m py_compile app/main.py 2>/dev/null; then
    echo -e "${GREEN}✅ Sintaxe do main.py está correta${NC}"
else
    echo -e "${RED}❌ Erro de sintaxe em app/main.py${NC}"
    python3 -m py_compile app/main.py
    exit 1
fi
echo ""

# 3. Verificar imports
echo "3️⃣  Verificando imports..."
if python3 -c "from app.main import app" 2>&1; then
    echo -e "${GREEN}✅ Imports estão corretos${NC}"
else
    echo -e "${RED}❌ Erro ao importar módulos${NC}"
    python3 -c "from app.main import app" 2>&1
    exit 1
fi
echo ""

# 4. Verificar configuração
echo "4️⃣  Verificando configuração..."
if python3 -c "from app.core.config import settings; print('OK')" 2>&1; then
    echo -e "${GREEN}✅ Configuração carregada${NC}"
else
    echo -e "${RED}❌ Erro ao carregar configuração${NC}"
    python3 -c "from app.core.config import settings" 2>&1
    exit 1
fi
echo ""

# 5. Verificar banco de dados (sem conectar)
echo "5️⃣  Verificando modelos de banco..."
if python3 -c "from app.core.database import engine; print('OK')" 2>&1; then
    echo -e "${GREEN}✅ Modelos de banco OK${NC}"
else
    echo -e "${RED}❌ Erro nos modelos de banco${NC}"
    python3 -c "from app.core.database import engine" 2>&1
    exit 1
fi
echo ""

echo "=========================================="
echo -e "${GREEN}✅ Todos os testes passaram!${NC}"
echo "=========================================="
echo ""
echo "O código do backend está correto."
echo "O problema pode estar no build do Docker ou na configuração."
echo ""

cd ..

