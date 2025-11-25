#!/bin/bash

echo "=========================================="
echo "🔍 DESCOBRINDO ONDE ESTÃO OS DADOS - DEBRIEF"
echo "=========================================="
echo ""

# Cores
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Executar no servidor via SSH
ssh debrief << 'ENDSSH'
    set -e
    cd /var/www/debrief
    
    echo -e "\033[0;34m1️⃣ Verificando containers rodando:\033[0m"
    docker ps --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}"
    echo ""
    
    echo -e "\033[0;34m2️⃣ Verificando qual docker-compose está sendo usado:\033[0m"
    if docker ps | grep -q "debrief_db"; then
        echo -e "\033[1;33m⚠️  Container 'debrief_db' ENCONTRADO - Usando BANCO LOCAL EM CONTAINER\033[0m"
        echo "   Os dados estão no volume Docker do container"
        BANCO_LOCAL=true
    else
        echo -e "\033[0;32m✅ Container 'debrief_db' NÃO encontrado - Usando BANCO REMOTO\033[0m"
        BANCO_LOCAL=false
    fi
    echo ""
    
    echo -e "\033[0;34m3️⃣ Configuração DATABASE_URL do backend:\033[0m"
    docker exec debrief-backend env | grep DATABASE_URL || echo "❌ Variável não encontrada"
    echo ""
    
    echo -e "\033[0;34m4️⃣ Testando conexão do container backend:\033[0m"
    docker exec debrief-backend python -c "
from app.core.config import settings
print(f'DATABASE_URL configurado: {settings.DATABASE_URL}')
"
    echo ""
    
    echo -e "\033[0;34m5️⃣ Verificando arquivo .env do backend:\033[0m"
    if [ -f backend/.env ]; then
        echo "✅ Arquivo backend/.env existe"
        echo "Conteúdo da variável DATABASE_URL:"
        grep "^DATABASE_URL" backend/.env || echo "DATABASE_URL não definido no .env"
    else
        echo "❌ Arquivo backend/.env NÃO existe"
    fi
    echo ""
    
    if [ "$BANCO_LOCAL" = true ]; then
        echo -e "\033[0;34m6️⃣ Verificando banco LOCAL (container debrief_db):\033[0m"
        echo "Listando bancos de dados no container:"
        docker exec debrief_db psql -U postgres -c "\l"
        echo ""
        echo "Listando tabelas no banco 'dbrief':"
        docker exec debrief_db psql -U postgres -d dbrief -c "\dt"
        echo ""
        echo "Contando registros:"
        docker exec debrief_db psql -U postgres -d dbrief -c "
            SELECT 'usuarios' as tabela, COUNT(*) FROM usuarios
            UNION ALL
            SELECT 'demandas', COUNT(*) FROM demandas
            UNION ALL
            SELECT 'secretarias', COUNT(*) FROM secretarias;
        " 2>/dev/null || echo "Erro ao consultar tabelas"
    else
        echo -e "\033[0;34m6️⃣ Verificando banco REMOTO:\033[0m"
        echo "Tentando conexão com PostgreSQL local do servidor..."
        PGPASSWORD='Mslestra@2025db' psql -h localhost -U postgres -d dbrief -c "\dt" 2>/dev/null && {
            echo "✅ Conectado ao PostgreSQL LOCAL do servidor!"
            echo ""
            echo "Contando registros:"
            PGPASSWORD='Mslestra@2025db' psql -h localhost -U postgres -d dbrief -c "
                SELECT 'usuarios' as tabela, COUNT(*) FROM usuarios
                UNION ALL
                SELECT 'demandas', COUNT(*) FROM demandas
                UNION ALL
                SELECT 'secretarias', COUNT(*) FROM secretarias;
            " 2>/dev/null
        } || {
            echo "❌ Não foi possível conectar ao PostgreSQL local"
        }
    fi
    echo ""
    
    echo -e "\033[0;34m7️⃣ Últimos logs do backend (erros de conexão):\033[0m"
    docker logs debrief-backend 2>&1 | grep -i -E "database|connection|error" | tail -15
    echo ""
    
    echo -e "\033[0;34m8️⃣ Verificando volumes Docker:\033[0m"
    docker volume ls | grep debrief
    echo ""
    
    echo "=========================================="
    echo -e "\033[0;32m✅ Diagnóstico completo!\033[0m"
    echo "=========================================="
ENDSSH

echo ""
echo "=========================================="
echo "📋 PRÓXIMOS PASSOS:"
echo "=========================================="
echo ""
echo "Com base no diagnóstico acima, você saberá:"
echo "1. Se os dados estão em um container Docker local (debrief_db)"
echo "2. Se os dados estão no PostgreSQL local do servidor"
echo "3. A URL de conexão que o backend está usando"
echo ""
echo "Para acessar via DBeaver:"
echo "- Se container local: precisa criar um túnel SSH"
echo "- Se PostgreSQL local: precisa configurar pg_hba.conf para aceitar conexões remotas"
echo ""


