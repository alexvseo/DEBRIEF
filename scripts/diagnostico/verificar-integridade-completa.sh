#!/bin/bash

# Script de Verificação de Integridade Completa do DeBrief
# Verifica conexão com banco de dados e status geral da aplicação

echo "=================================================="
echo "🔍 DIAGNÓSTICO COMPLETO - DEBRIEF"
echo "=================================================="
echo ""

SERVER="root@82.25.92.217"
APP_DIR="/var/www/debrief"

echo "📡 Conectando ao servidor $SERVER..."
echo ""

ssh $SERVER << 'ENDSSH'

echo "1️⃣ VERIFICANDO CONTAINERS DOCKER"
echo "=================================================="
cd /var/www/debrief
docker ps -a --filter "name=debrief"
echo ""

echo "2️⃣ VERIFICANDO STATUS DOS SERVIÇOS"
echo "=================================================="
docker-compose ps
echo ""

echo "3️⃣ VERIFICANDO LOGS DO BACKEND (últimas 30 linhas)"
echo "=================================================="
docker logs debrief-backend --tail 30
echo ""

echo "4️⃣ VERIFICANDO LOGS DO BANCO DE DADOS (últimas 20 linhas)"
echo "=================================================="
docker logs debrief_db --tail 20
echo ""

echo "5️⃣ VERIFICANDO CONECTIVIDADE BACKEND -> BANCO"
echo "=================================================="
docker exec debrief-backend sh -c "ping -c 3 debrief_db 2>/dev/null || echo 'Ping não disponível, testando conexão TCP...'"
docker exec debrief-backend sh -c "nc -zv debrief_db 5432 2>&1 || echo 'Netcat não disponível'"
echo ""

echo "6️⃣ VERIFICANDO VARIÁVEIS DE AMBIENTE DO BACKEND"
echo "=================================================="
docker exec debrief-backend sh -c "env | grep -E '(DATABASE|DB_|POSTGRES)' | sort"
echo ""

echo "7️⃣ TESTANDO CONEXÃO DIRETA AO BANCO"
echo "=================================================="
docker exec debrief_db psql -U postgres -d dbrief -c "SELECT 'Conexão OK!' as status, version();"
echo ""

echo "8️⃣ VERIFICANDO TABELAS NO BANCO"
echo "=================================================="
docker exec debrief_db psql -U postgres -d dbrief -c "\dt"
echo ""

echo "9️⃣ CONTANDO REGISTROS NAS TABELAS PRINCIPAIS"
echo "=================================================="
docker exec debrief_db psql -U postgres -d dbrief -c "
SELECT 'users' as tabela, COUNT(*) as registros FROM users
UNION ALL
SELECT 'demandas', COUNT(*) FROM demandas
UNION ALL
SELECT 'clientes', COUNT(*) FROM clientes
ORDER BY tabela;
"
echo ""

echo "🔟 VERIFICANDO CONFIGURAÇÃO DE REDE DOCKER"
echo "=================================================="
docker network inspect debrief_default 2>/dev/null | grep -A 20 "Containers" || docker network ls | grep debrief
echo ""

echo "1️⃣1️⃣ VERIFICANDO ARQUIVO .env DO BACKEND"
echo "=================================================="
if [ -f /var/www/debrief/backend/.env ]; then
    echo "✅ Arquivo .env existe"
    grep -E "(DATABASE_URL|DB_|POSTGRES)" /var/www/debrief/backend/.env | sed 's/=[^@]*@/=***@/g'
else
    echo "❌ Arquivo .env NÃO encontrado!"
fi
echo ""

echo "1️⃣2️⃣ TESTANDO ENDPOINT DE HEALTH DO BACKEND"
echo "=================================================="
curl -s http://localhost:2023/health || curl -s http://localhost:2023/ || echo "❌ Backend não está respondendo"
echo ""

echo "1️⃣3️⃣ TESTANDO ENDPOINT RAIZ DO BACKEND"
echo "=================================================="
curl -s http://localhost:2023/api/ || echo "❌ API não está respondendo"
echo ""

echo "1️⃣4️⃣ VERIFICANDO PROCESSOS E PORTAS"
echo "=================================================="
netstat -tlnp | grep -E "(2023|2022|5432)" || ss -tlnp | grep -E "(2023|2022|5432)"
echo ""

echo "1️⃣5️⃣ VERIFICANDO USO DE RECURSOS"
echo "=================================================="
docker stats --no-stream --format "table {{.Name}}\t{{.CPUPerc}}\t{{.MemUsage}}" $(docker ps -q --filter "name=debrief")
echo ""

echo "=================================================="
echo "✅ DIAGNÓSTICO COMPLETO FINALIZADO"
echo "=================================================="

ENDSSH

echo ""
echo "💡 Diagnóstico executado!"
echo ""
echo "Se houver problemas de conexão, execute:"
echo "  ./scripts/diagnostico/corrigir-conexao-banco.sh"


