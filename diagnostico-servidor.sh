#!/bin/bash

# ========================================
# SCRIPT PARA EXECUTAR NO SERVIDOR VPS
# Execute este script DENTRO do servidor 82.25.92.217
# ========================================

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

cd /var/www/debrief

echo -e "${BLUE}1️⃣ Verificando containers rodando:${NC}"
docker ps --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}"
echo ""

echo -e "${BLUE}2️⃣ Verificando qual banco está sendo usado:${NC}"
if docker ps | grep -q "debrief_db"; then
    echo -e "${YELLOW}⚠️  Container 'debrief_db' ENCONTRADO - Usando BANCO LOCAL EM CONTAINER${NC}"
    echo "   Os dados estão no volume Docker do container"
    BANCO_LOCAL=true
else
    echo -e "${GREEN}✅ Container 'debrief_db' NÃO encontrado - Usando BANCO REMOTO${NC}"
    BANCO_LOCAL=false
fi
echo ""

echo -e "${BLUE}3️⃣ Configuração DATABASE_URL do backend:${NC}"
docker exec debrief-backend env | grep DATABASE_URL || echo "❌ Variável não encontrada"
echo ""

echo -e "${BLUE}4️⃣ Testando conexão do container backend:${NC}"
docker exec debrief-backend python -c "
from app.core.config import settings
print(f'DATABASE_URL configurado: {settings.DATABASE_URL}')
" 2>&1
echo ""

echo -e "${BLUE}5️⃣ Verificando arquivo .env do backend:${NC}"
if [ -f backend/.env ]; then
    echo "✅ Arquivo backend/.env existe"
    echo "Conteúdo da variável DATABASE_URL:"
    grep "^DATABASE_URL" backend/.env || echo "DATABASE_URL não definido no .env"
else
    echo "❌ Arquivo backend/.env NÃO existe"
fi
echo ""

if [ "$BANCO_LOCAL" = true ]; then
    echo -e "${BLUE}6️⃣ Verificando banco LOCAL (container debrief_db):${NC}"
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
    echo -e "${BLUE}6️⃣ Verificando banco REMOTO (PostgreSQL local):${NC}"
    echo "Tentando conexão com PostgreSQL local do servidor..."
    
    # Tentar com diferentes credenciais
    echo "Tentando com usuário 'postgres' e senha '<redacted-db-password>':"
    PGPASSWORD='<redacted-db-password>' psql -h localhost -U postgres -d dbrief -c "\dt" 2>/dev/null && {
        echo "✅ Conectado ao PostgreSQL LOCAL do servidor!"
        echo ""
        echo "Contando registros:"
        PGPASSWORD='<redacted-db-password>' psql -h localhost -U postgres -d dbrief -c "
            SELECT 'usuarios' as tabela, COUNT(*) FROM usuarios
            UNION ALL
            SELECT 'demandas', COUNT(*) FROM demandas
            UNION ALL
            SELECT 'secretarias', COUNT(*) FROM secretarias;
        " 2>/dev/null
    } || {
        echo "Tentando com usuário 'root' e senha '<redacted-db-password>':"
        PGPASSWORD='<redacted-db-password>' psql -h localhost -U root -d dbrief -c "\dt" 2>/dev/null && {
            echo "✅ Conectado com usuário 'root'!"
            PGPASSWORD='<redacted-db-password>' psql -h localhost -U root -d dbrief -c "
                SELECT 'usuarios' as tabela, COUNT(*) FROM usuarios
                UNION ALL
                SELECT 'demandas', COUNT(*) FROM demandas
                UNION ALL
                SELECT 'secretarias', COUNT(*) FROM secretarias;
            "
        } || {
            echo "❌ Não foi possível conectar ao PostgreSQL local"
        }
    }
fi
echo ""

echo -e "${BLUE}7️⃣ Últimos logs do backend (conexões de banco):${NC}"
docker logs debrief-backend 2>&1 | grep -i -E "database|connection|sqlalchemy" | tail -10
echo ""

echo -e "${BLUE}8️⃣ Verificando volumes Docker:${NC}"
docker volume ls | grep debrief
echo ""

echo -e "${BLUE}9️⃣ Verificando serviços PostgreSQL no sistema:${NC}"
systemctl list-units | grep postgres || echo "PostgreSQL não está rodando como serviço do sistema"
echo ""

echo -e "${BLUE}🔟 Verificando portas PostgreSQL abertas:${NC}"
ss -tuln | grep 5432 || echo "Porta 5432 não está aberta"
echo ""

echo "=========================================="
echo -e "${GREEN}✅ Diagnóstico completo!${NC}"
echo "=========================================="
echo ""
echo "RESUMO:"
echo "- Se você viu o container 'debrief_db': os dados estão no container Docker"
echo "- Se não viu o container 'debrief_db': os dados estão no PostgreSQL local"
echo "- A variável DATABASE_URL mostra exatamente onde o backend está conectando"
echo ""





