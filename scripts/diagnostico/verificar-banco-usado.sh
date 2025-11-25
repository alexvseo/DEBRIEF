#!/bin/bash

echo "=========================================="
echo "🔍 VERIFICANDO QUAL BANCO ESTÁ SENDO USADO"
echo "=========================================="
echo ""

# Cores
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

echo -e "${BLUE}Conectando ao servidor...${NC}"
echo ""

ssh root@82.25.92.217 << 'ENDSSH'
    cd /var/www/debrief
    
    echo -e "\033[0;34m1️⃣ Verificando containers rodando:\033[0m"
    docker ps --format "table {{.Names}}\t{{.Status}}" | grep -E "NAME|debrief"
    echo ""
    
    echo -e "\033[0;34m2️⃣ Verificando DATABASE_URL do backend:\033[0m"
    echo "DATABASE_URL configurado:"
    docker exec debrief-backend env | grep DATABASE_URL
    echo ""
    
    echo -e "\033[0;34m3️⃣ Testando qual banco o backend está REALMENTE usando:\033[0m"
    docker exec debrief-backend python -c "
import os
from sqlalchemy import create_engine, text

# Pegar DATABASE_URL do ambiente
database_url = os.getenv('DATABASE_URL')
print(f'DATABASE_URL: {database_url}')
print()

# Conectar e verificar
engine = create_engine(database_url)
with engine.connect() as conn:
    # Ver em qual host está conectado
    result = conn.execute(text('SELECT inet_server_addr(), inet_server_port();'))
    row = result.fetchone()
    print(f'Servidor PostgreSQL: {row[0]}:{row[1]}')
    print()
    
    # Contar demandas
    result = conn.execute(text('SELECT COUNT(*) FROM demandas'))
    count = result.fetchone()[0]
    print(f'Total de demandas no banco: {count}')
    print()
    
    # Listar últimas demandas
    print('Últimas 5 demandas:')
    result = conn.execute(text('SELECT id, titulo, status FROM demandas ORDER BY created_at DESC LIMIT 5'))
    for row in result:
        print(f'  - ID {row[0]}: {row[1]} [{row[2]}]')
" 2>&1
    echo ""
    
    echo -e "\033[0;34m4️⃣ Se existe container debrief_db, verificar dados nele:\033[0m"
    if docker ps | grep -q debrief_db; then
        echo "✅ Container debrief_db ENCONTRADO!"
        echo ""
        echo "Dados no container debrief_db:"
        docker exec debrief_db psql -U postgres -d dbrief -c "SELECT COUNT(*) as total_demandas FROM demandas;" 2>/dev/null
        echo ""
        echo "Últimas demandas no debrief_db:"
        docker exec debrief_db psql -U postgres -d dbrief -c "SELECT id, titulo, status FROM demandas ORDER BY created_at DESC LIMIT 5;" 2>/dev/null
    else
        echo "❌ Container debrief_db NÃO encontrado"
    fi
    echo ""
    
    echo -e "\033[0;34m5️⃣ Verificando arquivo .env do backend:\033[0m"
    if [ -f backend/.env ]; then
        echo "Conteúdo do DATABASE_URL no .env:"
        grep "DATABASE_URL" backend/.env | head -1
    else
        echo "❌ Arquivo backend/.env não existe"
    fi
    echo ""
    
    echo -e "\033[0;34m6️⃣ Verificando qual docker-compose está sendo usado:\033[0m"
    if [ -f docker-compose.override.yml ]; then
        echo "⚠️  Existe docker-compose.override.yml (tem prioridade!)"
        cat docker-compose.override.yml
    else
        echo "Não há docker-compose.override.yml"
    fi
    echo ""
    
    echo "Docker-compose principal sendo usado:"
    if docker ps | grep -q debrief_db; then
        echo "→ docker-compose.prod.yml (com container debrief_db local)"
    else
        echo "→ docker-compose.yml (com banco remoto)"
    fi
    echo ""
    
    echo "=========================================="
    echo -e "\033[0;32m✅ Diagnóstico completo!\033[0m"
    echo "=========================================="
ENDSSH

echo ""
echo "=========================================="
echo "📋 ANÁLISE:"
echo "=========================================="
echo ""
echo "Se o backend mostrou 12 demandas:"
echo "  → Está usando o banco com 12 demandas (provavelmente debrief_db)"
echo ""
echo "Se você conectou no DBeaver e viu 3 demandas:"
echo "  → Conectou em um banco DIFERENTE do que o backend usa"
echo ""
echo "Solução: Ajustar configuração para usar apenas UM banco"
echo ""



